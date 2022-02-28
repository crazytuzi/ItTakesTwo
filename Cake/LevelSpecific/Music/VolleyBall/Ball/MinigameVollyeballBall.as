import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;

import void AddBallToPlayerComponent(AHazePlayerCharacter, AMinigameVolleyballBall) from "Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer";
import void RemoveBallFromPlayerComponent(AHazePlayerCharacter, AMinigameVolleyballBall) from "Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer";
import void ApplyPlayerAnimation(AHazePlayerCharacter, EMinigameVolleyballMoveType) from "Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer";

void RemovePotentialOutsideBall(AActor PotentialBall)
{
	auto Ball = Cast<AMinigameVolleyballBall>(PotentialBall);
	if(Ball != nullptr)
	{
		Ball.Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(Ball, n"Crumb_BallIsOutsideField"), FHazeDelegateCrumbParams());	
	}
}

enum EMinigameVolleyballMoveType
{
	None,
	Serve,
	UpAndOver,
	Smash,
	Decending,
	DecendingToFail,
}

struct FVolleyballHitBallData
{
	bool bHasTouchedBall = false;
	bool bIsBadTouch = false;
	bool bSwappedPlayer = false;
}

struct FVolleyballReplicatedEOLData
{
	UPROPERTY()
	AMinigameVolleyballBall Ball;

	UPROPERTY()
	UNiagaraSystem EffectToSpawn;

	UPROPERTY()
	EHazePlayer ScoringPlayer = EHazePlayer::MAX;

	FVolleyballReplicatedEOLData(AMinigameVolleyballBall _Ball = nullptr)
	{
		Ball = _Ball;
	}
}

class UMinigameVolleyballMovementComponent : UHazeMovementComponent
{
	AMinigameVolleyballBall BallOwner;

	UFUNCTION(BlueprintOverride)
	float GetGravityMultiplier() const
	{
		return BallOwner.GetMovementGravity();
	}
}

struct FCustomGravityData
{
	private float Value = -1;
	private FHazeMinMax Time = FHazeMinMax(-1, -1);

	void Set(float NewValue, float ForTime = -1)
	{
		if(NewValue >= 0)
		{
			Value = NewValue;
			Time = FHazeMinMax(ForTime, ForTime);
		}
	}

	void Update(float DeltaTime)
	{
		if(Time.Max > 0)
		{
			Time.Min = Time.Min - DeltaTime;
			if(Time.Min <= 0)
			{
				Time = FHazeMinMax(-1, -1);
				Value = -1;
			}
		}
	}

	float GetValue(float WantedValue) const
	{
		if(Time.Max > 0)
		{
			const float CustomGravityAlpha = Time.Min / Time.Max;
			return FMath::Lerp(WantedValue, Value, CustomGravityAlpha);
		}
		else if(Value >= 0)
		{
			return Value;
		}
		else
		{
			return WantedValue;
		}
	}

}

UCLASS(Abstract)
class AMinigameVolleyballBall : AHazeActor
{
	default SetTickGroup(ETickingGroup::TG_PrePhysics);

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;
	default Root.CollisionProfileName = n"PlayerCharacter";
	default Root.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent ImpactSize;
	default ImpactSize.CollisionProfileName = n"OverlapAllDynamic";
	default ImpactSize.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent MeshOffset;
	
	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UMinigameVolleyballMovementComponent Movement;

	UPROPERTY(EditDefaultsOnly, Category = "Default|Gravity")
	float GravityMultiplier = 1.f;

	// Time; -1 going down, to 1 going up
	UPROPERTY(EditDefaultsOnly, Category = "Default|Gravity")
	FRuntimeFloatCurve VerticalMovementDirToGravity;

	// Time; the distance to the ground
	UPROPERTY(EditDefaultsOnly, Category = "Default|Gravity")
	FRuntimeFloatCurve DistanceToGroundToGravity;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent PlayerHitBallAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent PlayerSmashBallAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent BallDestroyedAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent JudgeServeBallAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent Crumb;
	default Crumb.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default Crumb.UpdateSettings.OptimalCount = 2;
	default ReplicateAsPhysicsObject();

	UPROPERTY(DefaultComponent)
	UTextRenderComponent CodyText;
	default CodyText.Text = FText();

	UPROPERTY(DefaultComponent)
	UTextRenderComponent MayText;
	default MayText.Text = FText();

	UPROPERTY(DefaultComponent, Category = "Effect")
	UNiagaraComponent RegularTrail;
	default RegularTrail.bAutoActivate = false;
	default RegularTrail.Deactivate();

	UPROPERTY(DefaultComponent, Category = "Effect")
	UNiagaraComponent SmashTrail;
	default SmashTrail.bAutoActivate = false;
	default SmashTrail.Deactivate();

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem GroundImpactEffectType;

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem PlayerImpactEffectType;
	
	protected EMinigameVolleyballMoveType _MovingType = EMinigameVolleyballMoveType::None;
	EHazePlayer _ControllingPlayer = EHazePlayer::Cody;
	TArray<USceneComponent> _TargetLocations;
	USceneComponent _CenterLocation;
	UBoxComponent _Net;
	float _GroundZ = 0;

	bool bIsMainBall = false;
	int MainBallBouncsesLeftToNewBall = 0;
	bool bHasBeenUpdatedByAPlayer = false;
	int ValidBounces = 0;

	bool bIsOutsidePlayField = false;
	TArray<FVector> PendingControlSideImpulses;
	FVector VelocityPrediction;
	float ActiveBallTime = 0;

	FCustomGravityData CustomGravity;
	FCustomGravityData CustomDistanceToGroundGravity;
	FCustomGravityData CustomVerticalDirectionGravity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Movement.Setup(Root);
		Movement.BallOwner = this;

		CodyText.SetRenderedForPlayer(Game::GetCody(), true);
		CodyText.SetRenderedForPlayer(Game::GetMay(), false);
		MayText.SetRenderedForPlayer(Game::GetMay(), true);
		MayText.SetRenderedForPlayer(Game::GetCody(), false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector CodyCameraLoc = Game::GetCody().GetCurrentlyUsedCamera().GetWorldLocation();
		CodyText.SetWorldRotation((CodyCameraLoc - CodyText.GetWorldLocation()).Rotation());

		FVector MayCameraLoc = Game::GetMay().GetCurrentlyUsedCamera().GetWorldLocation();
		MayText.SetWorldRotation((MayCameraLoc - MayText.GetWorldLocation()).Rotation());

		ActiveBallTime += DeltaTime;

		CustomGravity.Update(DeltaTime);
		CustomDistanceToGroundGravity.Update(DeltaTime);
		CustomVerticalDirectionGravity.Update(DeltaTime);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_BallIsOutsideField(const FHazeDelegateCrumbData& CrumbData)
	{
		bIsOutsidePlayField = true;
	}

	FVolleyballHitBallData HitByPlayer(AHazePlayerCharacter Player, bool bPlayerIsGrounded, bool bPlayerIsDashing)
	{
		ensure(false); // Not implemented
		return FVolleyballHitBallData();
	}

	bool IsValidUpdate(AHazePlayerCharacter Player, FVolleyballHitBallData Data, FVolleyballReplicatedEOLData& OutUpdateData) const
	{
		ensure(false); // Not implemented
		return false;
	}

	void AddSpawnForce(bool bGoodBall)
	{
		if(!HasControl())
	 		return;

		RemoveCustomGravity();

		CustomVerticalDirectionGravity.Set(1.2f, 0.25f);
		float Gravity = Movement.GetGravityMagnitude();
	
		FVector From = GetActorLocation();
		FVector To = _TargetLocations[int(_ControllingPlayer)].GetWorldLocation();
		
		FVector OffsetDir = FRotator(0.f, FMath::RandRange(-180, 180), 0.f).Vector();
		if(bGoodBall)
			OffsetDir *= FMath::RandRange(0, 200);
		else
			OffsetDir *= FMath::RandRange(200, 400);
		To += OffsetDir;
		To += (To - From).ConstrainToPlane(FVector::ZeroVector).GetSafeNormal() * 1500.f;
	
		float Height = 500.f;
		FOutCalculateVelocity TrajectoryData = CalculateParamsForPathWithHeight(From, To, Gravity, Height);
		FVector WantedImpulse = TrajectoryData.Velocity;

		PendingControlSideImpulses.Add(WantedImpulse);

		FHazeDelegateCrumbParams Params;
		Params.AddVector(n"InitialVelocity", WantedImpulse.GetSafeNormal());
		Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AddSpawnForce"), Params);	
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_AddSpawnForce(const FHazeDelegateCrumbData& CrumbData)
	{
		UHazeAkComponent::HazePostEventFireForget(JudgeServeBallAudioEvent, GetActorTransform());
		_MovingType = EMinigameVolleyballMoveType::Serve;
		RegularTrail.Activate();
		SmashTrail.Deactivate();	
	}

	void AddServeForce(AHazePlayerCharacter Player)
	{
		if(!HasControl())
	 		return;

		if(_MovingType != EMinigameVolleyballMoveType::Decending)
			return;

		FHazeDelegateCrumbParams Params;
		Params.AddObject(n"Player", Player);
		Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AddServeForce"), Params);	
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_AddServeForce(const FHazeDelegateCrumbData& CrumbData)
	{
		if(!OnServeForceAdded())
			return;

		_MovingType = EMinigameVolleyballMoveType::Serve;
		RegularTrail.Deactivate();
		SmashTrail.Deactivate();
		RemoveCustomGravity();
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		ApplyPlayerAnimation(Player, _MovingType);
		Player.PlayerHazeAkComp.HazePostEvent(PlayerHitBallAudioEvent);
		
		if(!HasControl())
			return;

		CustomGravity.Set(1.5f);
		CustomVerticalDirectionGravity.Set(1.f);
		MeshOffset.FreezeAndResetWithTime(0.4f);
		FVector NewWantedLocation = Game::GetPlayer(ControllingPlayer).GetActorLocation();
		NewWantedLocation.Z = GetActorLocation().Z;
		SetActorLocation(NewWantedLocation);
		Movement.StopMovement();
		PendingControlSideImpulses.Add(FVector::UpVector * 1500);	
	}

	void AddUpAndOverForce(AHazePlayerCharacter Player, float BonusHeigh = 0)
	{
		if(!HasControl())
	 		return;

		if(_MovingType != EMinigameVolleyballMoveType::Decending)
			return;

		FHazeDelegateCrumbParams Params;
		Params.AddObject(n"Player", Player);
		Params.AddVector(n"RelativeLocation", GetActorLocation() - Game::GetPlayer(_ControllingPlayer).GetActorLocation());
		Params.AddValue(n"BonusHeight", BonusHeigh);
		CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"Crumb_AddUpAndOverForce"), Params);
	}

	bool OnServeForceAdded(){ return true; }

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_AddUpAndOverForce(const FHazeDelegateCrumbData& CrumbData)
	{
		if(!OnUpAndOverForceAdded())
			return;

		MeshOffset.FreezeAndResetWithTime(0.2f);
		FVector NewWorldLocation = Game::GetPlayer(_ControllingPlayer).GetActorLocation();
		NewWorldLocation += CrumbData.GetVector(n"RelativeLocation");
		SetActorLocation(NewWorldLocation);

		_MovingType = EMinigameVolleyballMoveType::UpAndOver;
		RegularTrail.Activate();
		SmashTrail.Deactivate();
		RemoveCustomGravity();
		SwapWantedControllerSide();
		ValidBounces++;

		if(bIsMainBall && MainBallBouncsesLeftToNewBall > 0)
			MainBallBouncsesLeftToNewBall--;
		
		Niagara::SpawnSystemAtLocation(PlayerImpactEffectType, GetActorLocation(), GetActorRotation());
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		ApplyPlayerAnimation(Player, _MovingType);
		Player.PlayerHazeAkComp.HazePostEvent(PlayerHitBallAudioEvent);
		
		// Only the new controlside handles movement
		if(!HasControl())
		{
			VelocityPrediction = Movement.GetVelocity();
			Movement.StopMovement();	
		}
		else
		{
			CustomGravity.Set(2.2f);
			CustomVerticalDirectionGravity.Set(1.f, 0.25f);

			float Gravity = Movement.GetGravityMagnitude();
			CustomGravity.Set(FMath::RandRange(1.3f, 1.6f));
	
			Movement.StopMovement();		
			FVector From = GetActorLocation();
			FVector To = _TargetLocations[int(_ControllingPlayer)].GetWorldLocation();

			FVector OffsetDir = FRotator(0.f, FMath::RandRange(-180, 180), 0.f).Vector();
			OffsetDir *= FMath::RandRange(100.f, 500.f);
			To += OffsetDir;

			const float CurrentDistanceToNet = GetDistanceToNet();
			const float OffsetAlpha = FMath::Min(CurrentDistanceToNet / 4000.f, 1.f); 

			if(ValidBounces >= 2)
			{
				OffsetDir = (To - From).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				OffsetDir *= FMath::RandRange(
					FMath::Lerp(200.f, 50.f, OffsetAlpha), 
					FMath::Lerp(300.f, 125.f, OffsetAlpha));
				To += OffsetDir;
			}

			float Height = NetHeight + FMath::Lerp(400.f, 200.f, OffsetAlpha);
			Height += CrumbData.GetValue(n"BonusHeight");
			FOutCalculateVelocity TrajectoryData = CalculateParamsForPathWithHeight(From, To, Gravity, Height);
			FVector WantedImpulse = TrajectoryData.Velocity;
			PendingControlSideImpulses.Add(WantedImpulse);
		}
	}

	bool OnUpAndOverForceAdded(){ return true; }

	void AddSmashForce(AHazePlayerCharacter Player)
	{
		if(!HasControl())
	 		return;

		FVector DirToBall = (GetActorLocation() - Player.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();	
		FVector NetLocation;
		float Distance = _Net.GetClosestPointOnCollision(GetActorLocation(), NetLocation);
		FVector DirToNet = (NetLocation - Player.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal(); 

		if(DirToBall.DotProduct(DirToNet) < -0.25f)
		{
			AddUpAndOverForce(Player);
		}
		else if(GetDistanceToNet() < 100)
		{
			AddUpAndOverForce(Player);
		}
		else
		{	
			if(_MovingType == EMinigameVolleyballMoveType::DecendingToFail)
				return;

			if(_MovingType == EMinigameVolleyballMoveType::Smash)
				return;

			if(_MovingType == EMinigameVolleyballMoveType::UpAndOver)
				return;

			FHazeDelegateCrumbParams Params;
			Params.AddObject(n"Player", Player);
			Params.AddVector(n"RelativeLocation", GetActorLocation() - Game::GetPlayer(_ControllingPlayer).GetActorLocation());
			Params.AddVector(n"PlayerFacingDir", DirToBall);
			Params.AddVector(n"PlayerVelocity", Player.GetActorVelocity());
			CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"Crumb_AddSmashForce"), Params);
		}

	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_AddSmashForce(const FHazeDelegateCrumbData& CrumbData)
	{
		if(!OnSmashForceAdded())
			return;

		RemoveCustomGravity();
		SwapWantedControllerSide();
		ValidBounces++;
		_MovingType = EMinigameVolleyballMoveType::Smash;

		if(bIsMainBall && MainBallBouncsesLeftToNewBall > 0)
			MainBallBouncsesLeftToNewBall--;

		RegularTrail.Deactivate();
		SmashTrail.Activate();
		Niagara::SpawnSystemAtLocation(PlayerImpactEffectType, GetActorLocation(), GetActorRotation());
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		ApplyPlayerAnimation(Player, _MovingType);
		Player.PlayerHazeAkComp.HazePostEvent(PlayerSmashBallAudioEvent);

		// Only the new controlside handles movement
		if(!HasControl())
		{
			VelocityPrediction = Movement.GetVelocity();
			Movement.StopMovement();
		}
		else
		{
			Movement.StopMovement();
			FVector PlayerFacingDir = CrumbData.GetVector(n"PlayerFacingDir");
			FVector PlayerVelocity = CrumbData.GetVector(n"PlayerVelocity");

			CustomGravity.Set(7.f);
			CustomVerticalDirectionGravity.Set(1.f, 0.25f);
			float Gravity = Movement.GetGravityMagnitude();
			CustomGravity.Set(5.f);

			FVector From = GetActorLocation();
			FVector To = _CenterLocation.GetWorldLocation();
			To = _TargetLocations[int(_ControllingPlayer)].GetWorldLocation();
			FVector DirToTarget = (To - From).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			To -= DirToTarget * 800.f;
			
			const float VelocityAmount = FMath::Clamp(PlayerVelocity.Size(), 400.f, 600.f);
			FRotator NewRotation = DirToTarget.Rotation();
			NewRotation.Yaw += FMath::RandRange(-5, 5);
			float DirectionAlpha = FMath::RandRange(0.25f, 0.85f);
			NewRotation = FMath::LerpShortestPath(NewRotation, PlayerFacingDir.Rotation(), DirectionAlpha);

			To += NewRotation.Vector() * FMath::RandRange(VelocityAmount, VelocityAmount + 500.f);
			float Height = NetHeight + 300.f;
			FOutCalculateVelocity TrajectoryData = CalculateParamsForPathWithHeight(From, To, Gravity, Height);
			FVector WantedImpulse = TrajectoryData.Velocity;

			PendingControlSideImpulses.Add(WantedImpulse);
		}	
	}

	bool OnSmashForceAdded(){ return true; }

	void SetDecending()
	{
		if(_MovingType == EMinigameVolleyballMoveType::DecendingToFail)
			return;

		_MovingType = EMinigameVolleyballMoveType::Decending;
	}

	EMinigameVolleyballMoveType GetMovingType() const property
	{
		return _MovingType;
	}

	float GetDistanceToNet() const property
	{
		FVector ClosestPoint;
		float Distance  = _Net.GetClosestPointOnCollision(GetActorLocation(), ClosestPoint);
		devEnsure(Distance >= 0, "The ballnet needs collision enabled");
		return FMath::Max(Distance - Root.GetScaledSphereRadius(), 0.f);
	}

	float GetNetHeight() const property
	{
		return _Net.GetBoxExtent().Z + Root.GetCollisionShape().GetSphereRadius();
	}

	void RemoveCustomGravity()
	{
		CustomGravity = FCustomGravityData();
		CustomDistanceToGroundGravity = FCustomGravityData();
		CustomVerticalDirectionGravity = FCustomGravityData();
	}

	void SwapWantedControllerSide()
	{
		auto OldPlayer = Game::GetPlayer(_ControllingPlayer);

		if(_ControllingPlayer == EHazePlayer::Cody)
			_ControllingPlayer = EHazePlayer::May;
		else
			_ControllingPlayer = EHazePlayer::Cody;

		auto NewPlayer = Game::GetPlayer(_ControllingPlayer);
		SetControlSide(NewPlayer);
		RemoveBallFromPlayerComponent(OldPlayer, this);
		AddBallToPlayerComponent(NewPlayer, this);
		PendingControlSideImpulses.Reset();
	}

	EHazePlayer GetControllingPlayer() const property
	{
		return _ControllingPlayer;
	}

	float GetDistanceToGround() const
	{
		return FMath::Max(GetActorLocation().Z - _GroundZ, 0.f);
	}

	float GetMovementGravity() const
	{
		return GetGravityMultiplier();
	}

	protected float GetGravityMultiplier() const
	{
		const float FinalGravityMultiplier = CustomGravity.GetValue(GravityMultiplier);

		const float GroundDist = GetDistanceToGround();
		float DistanceToGroundGravity = DistanceToGroundToGravity.GetFloatValue(GroundDist, 1.f);
		DistanceToGroundGravity = CustomDistanceToGroundGravity.GetValue(DistanceToGroundGravity);

		FVector VelocityDir = Movement.GetVelocity().GetSafeNormal();
		if(VelocityDir.IsNearlyZero())
			VelocityDir = FVector::UpVector;

		const float MovementDir = VelocityDir.DotProduct(FVector::UpVector);
		float VerticalDirGravity = VerticalMovementDirToGravity.GetFloatValue(MovementDir, 1.f);
		VerticalDirGravity = CustomVerticalDirectionGravity.GetValue(VerticalDirGravity);

		return FinalGravityMultiplier * DistanceToGroundGravity * VerticalDirGravity;
	}
}
