import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;
import Peanuts.Spline.SplineComponent;
import Peanuts.Animation.Features.Tree.LocomotionFeatureFireFlies;
import Cake.LevelSpecific.Tree.DarkRoom.FireflyFlightComponent;
import Peanuts.Audio.AudioStatics;

namespace Firefly
{
	const float MinRadius = 50.f;
	const float MaxRadius = 300.f;
	const float MinAngularVelocity = 50.f;
	const float MaxAngularVelocity = 200.f;
	const float ParamAcceleration = 3.1f;
	const float ParamFriction = 1.4f;
}

struct FFireflyFloat
{
	float Value;
	float Target;
	float Velocity = 0.f;
	float ValueScale = 1.f;
	float AccelerationScale = 1.f;

	void Set(float InValue)
	{
		Value = Target = InValue;
	}

	void Update(float DeltaTime)
	{
		float Diff = (Target * ValueScale) - Value;
		Velocity += Diff * Firefly::ParamAcceleration * AccelerationScale * DeltaTime;
		Velocity -= Velocity * Firefly::ParamFriction * DeltaTime;

		Value += Velocity * DeltaTime;
	}
}
struct FFireflyVector
{
	FVector Value;
	FVector Target;
	FVector Velocity = 0.f;
	float ValueScale = 1.f;
	float AccelerationScale = 1.f;

	void Set(FVector InValue)
	{
		Value = Target = InValue;
	}

	void Update(float DeltaTime)
	{
		FVector Diff = (Target * ValueScale) - Value;
		Velocity += Diff * Firefly::ParamAcceleration * AccelerationScale * DeltaTime;
		Velocity -= Velocity * Firefly::ParamFriction * DeltaTime;

		Value += Velocity * DeltaTime;
	}
}

struct FFirefly
{
	USceneComponent OwnerComponent;
	FQuat Rotation = FQuat::Identity;

	FFireflyVector Velocity;
	FFireflyFloat Distance;

	FFireflyVector Center;
	FFireflyVector CenterOffset;

	FVector LastLocation;
	FVector CurrentLinearVelocity;

	AHazePlayerCharacter FollowPlayer;
	FVector PlayerLastLocation;
	FVector PlayerVelocity;
	bool bIsBoosting = false;

	float VelocityInheritance = 0.f;

	float ChangeTimer = 0.f;
	float PostLaunchTimer = 0.f;

	FVector LaunchDirection;

	void Init(USceneComponent Owner)
	{
		OwnerComponent = Owner;
		Rotation = FQuat::Identity;
		Distance.Set(Firefly::MaxRadius);
		Velocity.Set(FVector::ZeroVector);
		CenterOffset.Set(FVector::ZeroVector);
		Center.Set(Owner.WorldLocation);

		LastLocation = GetWorldLocation();
	}

	FVector GetRelativeLocation()
	{
		return OwnerComponent.WorldTransform.InverseTransformPosition(GetWorldLocation());
	}

	FVector GetWorldLocation()
	{
		return Center.Value + CenterOffset.Value + Rotation.Vector() * Distance.Value;
	}

	void StartFollowingPlayer(AHazePlayerCharacter Player)
	{
		FollowPlayer = Player;
		PlayerLastLocation = Player.ActorCenterLocation;
	}

	void StopFollowingPlayer()
	{
		FollowPlayer = nullptr;
	}

	void LaunchPlayer()
	{
		LaunchDirection = Center.Velocity.GetSafeNormal();
		FVector Offset = GetWorldLocation() - FollowPlayer.ActorLocation;
		Offset = Offset.ConstrainToPlane(LaunchDirection);

		Center.Velocity = FollowPlayer.ActualVelocity * 2.5f + Offset * 5.f;
		PostLaunchTimer = 4.f;
		StopFollowingPlayer();
	}

	void SetIsBoosting(bool bInBoosting)
	{
		bIsBoosting = bInBoosting;
	}

	void Update(float DeltaTime)
	{
		FQuat DeltaQuat = FQuat(Velocity.Value.GetSafeNormal(), Velocity.Value.Size() * DEG_TO_RAD * DeltaTime);
		Rotation = DeltaQuat * Rotation;
		float DistanceFromCenter = (GetWorldLocation() - Center.Value).Size();
		float DistancePercent = Math::GetPercentageBetweenClamped(0.f, 800.f, DistanceFromCenter);

		bool bHasTarget = FollowPlayer != nullptr;

		if (bHasTarget)
		{
			Center.Target = FollowPlayer.ActorCenterLocation;

			FVector PlayerLocation = FollowPlayer.ActorCenterLocation;
			FVector PlayerDelta = PlayerLocation - PlayerLastLocation;
			PlayerLastLocation = PlayerLocation;

			FVector SelfDelta = PlayerDelta * (DistanceFromCenter / 100.f) * VelocityInheritance;

			Center.Value += SelfDelta;
			VelocityInheritance = FMath::FInterpTo(VelocityInheritance, 1.f, DeltaTime, 0.6f);
		}
		else if (PostLaunchTimer > 0.f)
		{
			PostLaunchTimer -= DeltaTime;
			Center.Target = FMath::VInterpTo(Center.Target, OwnerComponent.WorldLocation, DeltaTime, 1.f);

			FVector RotateAxis = LaunchDirection.CrossProduct(Center.Velocity);
			RotateAxis.Normalize();
			FQuat RotateQuat = FQuat(RotateAxis, -10.f * DEG_TO_RAD * DeltaTime);

			Center.Velocity = RotateQuat.RotateVector(Center.Velocity);
			VelocityInheritance = 0.f;
		}
		else
		{
			Center.Target = OwnerComponent.WorldLocation;
			VelocityInheritance = 0.f;
		}

		Distance.ValueScale = bHasTarget ? 0.4f : 1.f;
		Distance.Update(DeltaTime);
		Velocity.ValueScale = bHasTarget ? 7.f : 1.f;
		Velocity.Update(DeltaTime);

		CenterOffset.ValueScale = bHasTarget ? 0.2f : 1.f;
		CenterOffset.Update(DeltaTime);

		Center.AccelerationScale = 0.4f + 4.f * (1.f - Math::GetPercentageBetweenClamped(Firefly::MinRadius, Firefly::MaxRadius, Distance.Target));
		Center.Update(DeltaTime);

		// Draw debug shit
		if (false)
		{
			System::DrawDebugLine(Center.Value + CenterOffset.Value, GetWorldLocation());
			System::DrawDebugLine(Center.Value + CenterOffset.Value, Center.Value + CenterOffset.Value + Velocity.Value, FLinearColor::Red);
		}

		// Change parameters
		ChangeTimer -= DeltaTime;
		if (ChangeTimer < 0.f)
		{
			Distance.Target = FMath::RandRange(Firefly::MinRadius, Firefly::MaxRadius);

			FVector VeloAxis = Math::GetRandomPointOnSphere();
			float VeloMagnitude = FMath::RandRange(20.f, 200.f);
			Velocity.Target = VeloAxis * VeloMagnitude;

			CenterOffset.Target = Math::GetRandomPointOnSphere() * FMath::RandRange(0.f, 400.f);

			ChangeTimer = FMath::RandRange(0.5f, 2.4f);
		}

		// Calculate new linear velocity
		FVector NewLocation = GetWorldLocation();
		FVector DeltaMove = (NewLocation - LastLocation);
		if (!FMath::IsNearlyZero(DeltaTime))
			CurrentLinearVelocity = DeltaMove / DeltaTime;
		else
			CurrentLinearVelocity = FVector::ZeroVector;

		LastLocation = NewLocation;
	}

	FVector GetLinearVelocity()
	{
		return CurrentLinearVelocity;
	}

	FVector GetRelativeLinearVelocity()
	{
		return OwnerComponent.WorldTransform.InverseTransformVector(GetLinearVelocity());
	}
}

class AFireflySwarm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UPoseableMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent)
	USphereComponent SuckingSphereCollision;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent FlySpline;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Capability")
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(Category = "Audio Events")
	bool bShouldPlayVO = true;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireflyPlayerOutAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireflyPlayerInLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireflyPlayerInOneShotAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireflyLaunchStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireflyLaunchStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireflySummonAudioEvent;

	UPROPERTY(Category = "FX")
	UNiagaraSystem LaunchSystem;

	UPROPERTY(Category = "FX")
	UNiagaraSystem AttachedSystem;

	UPROPERTY()
	float Strength = 500.f;

	UPROPERTY()
	float Range = 1000.f;

	UPROPERTY()
	AActor FireflySwarmPOI;

	UPROPERTY()
	float MaxSuckForce = 150.f;

	
	UPROPERTY()
	float SpeedAlongSpline = 1000.f;

	UPROPERTY()
	bool bStartSpawned = true;

	UPROPERTY()
	UMaterial Material;

	int AttachedFireflyCount = 5;
	int MaxFlies = 120;

	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic DynamicMaterial;
	TArray<AHazePlayerCharacter> CurrentPlayers;

	// Spline stuff
	bool bMoveAlongSpline = false;
	float DistanceAlongSpline = 0.f;

	float TargetRange = 0.f;

	bool bHasBeenSummoned = false;

	UPROPERTY(NotEditable)
	TArray<FFirefly> Fireflies;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SphereCollision.SetSphereRadius(Range, false);
		SuckingSphereCollision.SetSphereRadius(Range + 500.f, false);
		DynamicMaterial = Material::CreateDynamicMaterialInstance(Material);
		Mesh.SetMaterial(0, DynamicMaterial);

		Fireflies.SetNum(MaxFlies);
		for(FFirefly& Firefly : Fireflies)
		{
			Firefly.Init(Mesh);
		}

		UpdateBones();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilitySheetRequest(PlayerSheet);

		SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		SphereCollision.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");	
		SuckingSphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"BeginSuckingOverlap");
		SuckingSphereCollision.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndSuckingOverlap");
		HazeAkComp.SetRTPCValue("Rtpc_WaspNest_Platform_FireflySwarm_Movement", 0.0, 0.f);	
		
		FlySpline.DetachFromParent(true, false);

		TargetRange = Range;
		
		if (!bStartSpawned)
		{
			SetActorHiddenInGame(true);
			Range = 0.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet);
	}

	UFUNCTION()
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		HazeAudio::SetPlayerPanning(HazeAkComp, Player);
		HazeAkComp.HazePostEvent(FireflyPlayerInOneShotAudioEvent);
		// Only play audio if this is the first player
		if (CurrentPlayers.Num() == 0)
			HazeAkComp.HazePostEvent(FireflyPlayerInLoopAudioEvent);

		HazeAudio::SetPlayerPanning(HazeAkComp, Player);

		auto FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
		FlightComp.OverlappingSwarms.AddUnique(this);
		FlightComp.TargetAttachedFireflies += AttachedFireflyCount;

		int NumPlayers = CurrentPlayers.Num();
		for(int i=0; i<100; ++i)
		{
			if (i % 2 != NumPlayers)
				continue;

			Fireflies[i].StartFollowingPlayer(Player);
		}

		CurrentPlayers.Add(Player);

		// POI to focus on next firefly swarm
		if (FireflySwarmPOI == nullptr)
			return;
	
		FHazePointOfInterest POISettings;
		POISettings.FocusTarget.Actor = FireflySwarmPOI;
		POISettings.Blend.BlendTime = 2.f;
		POISettings.Duration = 2.f;
		Player.ApplyPointOfInterest(POISettings, this);
	}

	UFUNCTION()
    void TriggeredOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		CurrentPlayers.Remove(Player);

		// Onlt stop the event if that was the last player exiting
		if (CurrentPlayers.Num() == 0)
			HazeAkComp.HazePostEvent(FireflyPlayerOutAudioEvent);
		
		Player.ClearPointOfInterestByInstigator(this);
		auto FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
		FlightComp.OverlappingSwarms.Remove(this);
		FlightComp.TargetAttachedFireflies -= AttachedFireflyCount;

		if (FlightComp.bIsLaunching)
		{
			FlightComp.bStartedFlight = true;
			Niagara::SpawnSystemAtLocation(LaunchSystem, Player.ActorLocation);
		}

		for(FFirefly& Firefly : Fireflies)
		{
			if (Firefly.FollowPlayer != Player)
				continue;

			if (FlightComp.bIsLaunching)
				Firefly.LaunchPlayer();
			else
				Firefly.StopFollowingPlayer();
		}
	}

	UFUNCTION()
	void BeginSuckingOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.SetCapabilityAttributeObject(n"CurrentFireflySwarm", this);
		}
	}

	UFUNCTION()
    void TriggeredOnEndSuckingOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {

	}

	UFUNCTION()
	void SummonFireflySwarm()
	{
		bMoveAlongSpline = true;
		SetActorHiddenInGame(false);

		if (!bHasBeenSummoned)
		{
			HazeAkComp.HazePostEvent(FireflyPlayerOutAudioEvent);
			HazeAkComp.HazePostEvent(FireflySummonAudioEvent);
		}

		bHasBeenSummoned = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bMoveAlongSpline)
		{
			FVector TargetSplinePosition;
			DistanceAlongSpline += SpeedAlongSpline * DeltaTime;
			float Time = Time::GetGameTimeSeconds();

			Range = FMath::GetMappedRangeValueClamped(FVector2D(0.f, FlySpline.GetSplineLength()), FVector2D(0.f, TargetRange), DistanceAlongSpline);

			TargetSplinePosition = FlySpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			TargetSplinePosition += FVector::UpVector * 100.f * FMath::Sin(Time);
			
			//if (DistanceAlongSpline >= FlySpline.GetSplineLength())
				//bMoveAlongSpline = false;
			
			SetActorLocation(TargetSplinePosition);
		}		

		for(auto& Firefly : Fireflies)
		{
			Firefly.Update(DeltaTime);
		}

		UpdateBones();
	}

	void OnStartLaunching()
	{
		HazeAkComp.HazePostEvent(FireflyLaunchStartAudioEvent);	
	}

	void OnStopLaunching()
	{
		HazeAkComp.HazePostEvent(FireflyLaunchStopAudioEvent);		
	}

	void ResetBones()
	{
		TArray<FTransform>& BoneTransforms = Mesh.BoneSpaceTransforms;
		for(int i=0; i<BoneTransforms.Num(); ++i)
		{
			BoneTransforms[i] = FTransform::Identity;
		}

		Mesh.MarkRefreshTransformDirty();
	}

	void UpdateBones()
	{
		ResetBones();

		TArray<FTransform>& BoneTransforms = Mesh.BoneSpaceTransforms;
		for(int i=3; i<BoneTransforms.Num(); ++i)
		{
			FTransform& Transform = BoneTransforms[i];

			if (i - 3 < MaxFlies)
			{
				Transform.Location = Fireflies[i - 3].GetRelativeLocation();
				FVector Velocity = Fireflies[i - 3].GetRelativeLinearVelocity();

				Transform.Rotation = Math::MakeQuatFromX(Velocity);

				float Stretch = Velocity.Size() / 2000.f;
				Transform.Scale3D = FVector(1.f + Stretch, 1.f, 1.f);
			}
			else
			{
				Transform.Location = FVector::OneVector * 50000.f;
			}

			BoneTransforms[i] = Transform;
		}

		Mesh.MarkRefreshTransformDirty();
	}
}