import Vino.Movement.Components.MovementComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Tree.Boat.TreeBoatForceVolume;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Boat.TreeBoatHealthWidget;

event void FOnTreeBoatImpact(ATreeBoat ImpactingBoat, AActor OtherActor);
event void FOnTreeBoatDestroyed(ATreeBoat DestroyedBoat);
event void FOnTreeBoatBigSplash(float SplashStrenght);

struct FTreeBoatForceVolumesArray
{
	TArray<ATreeBoatForceVolume> ForceVolumes;

	FTreeBoatForceVolumesArray(ATreeBoatForceVolume ForceVolume)
	{
		ForceVolumes.Add(ForceVolume);
	}
}

class ATreeBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent WorldCollision;

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent, Attach = RotationPivot)
	UHazeSkeletalMeshComponentBase AnimationComponent;

	UPROPERTY(DefaultComponent, Attach = AnimationComponent)
	UStaticMeshComponent TreeBoatMeshComponent;

	UPROPERTY(DefaultComponent, Attach = AnimationComponent)
	UNiagaraComponent SplashNiagaraComponent;

	UPROPERTY(DefaultComponent, Attach = AnimationComponent)
	UNiagaraComponent WaterNiagaraComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	default MovementComponent.bAllowOtherActorsToMoveWithTheActor = true;
	default MovementComponent.bDepenetrateOutOfOtherMovementComponents = false;

	UPROPERTY(DefaultComponent)
	UHazeInheritPlatformVelocityComponent InheritPlatformVelocityComponent;
	default InheritPlatformVelocityComponent.bInheritHorizontalVelocity = true;
	default InheritPlatformVelocityComponent.bInheritVerticalVelocity = true;	

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AudioEvent_StartMoving;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AudioEvent_StopMoving;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AudioEvent_Impact;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem SplashEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem LightImpactEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem HeavyImpactEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem DeathEffect;

	UPROPERTY(Category = "VFX")
	TArray<UStaticMesh> DamageMeshes;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> PlayerDeathEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCameraShakeClass;

	UPROPERTY()
	ALandscape WaterLandscape;

	UPROPERTY()
	float TreeBoatRadius = 800.f;

	UPROPERTY()
	bool bIsActivated = false;

	UPROPERTY()
	bool bIndestructible;

	UPROPERTY()
	bool bLeisureMode;

	UPROPERTY()
	bool bDrawDebug;

	UPROPERTY()
	bool bConstrainPlayers = true;

	UPROPERTY()
	float LerpInWobbleTime = 0.f;
	float LerpInWobbleTimer = 0.f;

	UPROPERTY()
	FVector Gravity = FVector(0.f, 0.f, -980.f) * 10.f;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	float Restitution = 0.5f;

	UPROPERTY()
	float Drag = 1.f;

	UPROPERTY()
	FVector AngularVelocity;

	UPROPERTY()
	float AngularDrag = 2.f;

	UPROPERTY()
	float ImpactCooldown = 1.f;
	float ImpactCooldownTimer = 0.f;

	UPROPERTY()
	FVector StreamForce = FVector::ZeroVector;

	UPROPERTY()
	FVector ForceVolumeForce;

	UPROPERTY()
	float SapThrottlePower = 2500.f;

	UPROPERTY()
	FVector SapThrottleForce;	

	UPROPERTY()
	FVector WaterUp;

	UPROPERTY()
	FVector LastSplashDirection;

	UPROPERTY()
	FVector SplashVelocity;

	UPROPERTY()
	float TreeBoatMaxHealth = 12.f;
	float TreeBoatHealth = TreeBoatMaxHealth;

	float RecentDamageTimer = 0.f;
	float RecentHealth = 1.f;
	float LastRecentHealth = 1.f;
	float HealthPercent = 1.f;
	bool bHasTriggeredAudioRegen = false;
	bool bDidTakeDamage = false;


	TMap<int, FTreeBoatForceVolumesArray> ForceVolumeGroups;

	TArray<AHazePlayerCharacter> Players;

	UPROPERTY()
	float ImpactDamageThreshold = 600.f;

	UPROPERTY()
	FOnTreeBoatImpact OnTreeBoatImpact;

	UPROPERTY()
	FOnTreeBoatDestroyed OnTreeBoatDestroyed;

	UPROPERTY()
	FOnTreeBoatBigSplash OnTreeBoatBigSplash;

	UPROPERTY()
	UHazeCapabilitySheet TreeBoatCapabilitySheet;

	UPROPERTY()
	TSubclassOf<UTreeBoatHealthWidget> TreeBoatHealthWidgetClass;

	UTreeBoatHealthWidget TreeBoatHealthWidget;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		WorldCollision.SetSphereRadius(TreeBoatRadius);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Cody Control in Network
		Network::SetActorControlSide(this, Game::GetCody());

		// Request Capability Sheet
		Capability::AddPlayerCapabilitySheetRequest(TreeBoatCapabilitySheet);

		// Setup MovementComponent Collision
		MovementComponent.Setup(WorldCollision);

		// Bind Events
		WorldCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnWorldCollisionBeginOverlap");
		WorldCollision.OnComponentEndOverlap.AddUFunction(this, n"OnWorldCollisionEndOverlap");

		HazeAkComp.HazePostEvent(AudioEvent_StartMoving);

		SplashNiagaraComponent.SetAsset(SplashEffect);
//		SplashNiagaraComponent.Activate();

		SplashNiagaraComponent.SetNiagaraVariableVec3("Strength", FVector(1.f, 1.f, 1.f));

		WaterNiagaraComponent.SetAsset(SplashEffect);
		WaterNiagaraComponent.SetRelativeLocation(FVector(0.f, 0.f, -100.f));
//		WaterNiagaraComponent.Activate();
		WaterNiagaraComponent.SetNiagaraVariableVec3("Strength", FVector(1.f, 1.f, 1.f));
		WaterNiagaraComponent.SetNiagaraVariableFloat("MinAngle", 0.0f);
		WaterNiagaraComponent.SetNiagaraVariableFloat("MaxAngle", 0.5f);
		WaterNiagaraComponent.SetNiagaraVariableVec2("MinSize", FVector2D(50.f, 50.f));
		WaterNiagaraComponent.SetNiagaraVariableVec2("MaxSize", FVector2D(1000.f, 1000.f));

		AddCapability(n"FullscreenSharedHealthAudioCapability");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// Remove Capability Sheet Request
		Capability::RemovePlayerCapabilitySheetRequest(TreeBoatCapabilitySheet);

		HazeAkComp.HazePostEvent(AudioEvent_StopMoving);

		RemoveHealthWidget();
	}

	UFUNCTION()
	void ActivateTreeBoat()
	{
		if (bIsActivated)
			return;

		bIsActivated = true;

		if (!bIndestructible)
			AddHealthWidget();

		SplashNiagaraComponent.Activate();
		WaterNiagaraComponent.Activate();

		// We want to move the mesh manually, otherwise the players "MoveWithFloor" will trigger
		//	twice; once when rotating the mesh, and once when moving the worldcollision
		RotationPivot.DetachFromParent();
		RotationPivot.SetWorldTransform(WorldCollision.WorldTransform);
	}

	UFUNCTION()
	void DeactivateTreeBoat()
	{
		if (!bIsActivated)
			return;

		bIsActivated = false;

		SplashNiagaraComponent.Deactivate();
		WaterNiagaraComponent.Deactivate();

		// Reattaches for cutscenes :)
		RotationPivot.AttachToComponent(WorldCollision, NAME_None, EAttachmentRule::SnapToTarget);
	}

	UFUNCTION()
	void LerpInWobble(float LerpTime)
	{
		LerpInWobbleTime = LerpTime;
		LerpInWobbleTimer = LerpInWobbleTime;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIsActivated)
			return;

		Move(DeltaTime);
		UpdateHealthWidget(DeltaTime);
		UpdateSplashes(DeltaTime);
		UpdateAudio(DeltaTime);
		CheckPlayerKillZone();

		// Consume SapThrottleForce
		SapThrottleForce = 0.f;

		if (bDrawDebug)
			DrawDebug();
	}

	UFUNCTION()
	void Move(float DeltaTime)
	{
		if (bDrawDebug)
			System::DrawDebugLine(RotationPivot.WorldLocation, RotationPivot.WorldLocation + RotationPivot.UpVector * 1000.f, FLinearColor::Green, 0.f, 20.f);

		// Update stream Location and Normal
		FVector StreamLocation;
		FVector StreamNormal;
		GetLocationAndNormalFromTraces(StreamLocation, StreamNormal, TreeBoatRadius, 6);

		WaterUp = StreamNormal;

		FVector CombinedForce = StreamForce + GetVolumeForce();

		// Limit SapThrottle to not add power if stream is stronger than SapPower
		float SapForceAlpha = FMath::Clamp(SapThrottleForce.GetSafeNormal().DotProduct(CombinedForce.GetSafeNormal()), 0.f, 1.f);
		FVector LimitedSapThrottleForce = SapThrottleForce - CombinedForce.GetClampedToMaxSize(SapThrottlePower) * SapForceAlpha * (SapThrottleForce.Size() / SapThrottlePower);

		if (bDrawDebug)
			PrintToScreen("LimitedSapThrottleForce: " + LimitedSapThrottleForce.Size());

		FVector Acceleration = Gravity
							 + CombinedForce
							 + LimitedSapThrottleForce							 
							 - Velocity * Drag;

		Velocity += Acceleration * DeltaTime;

		FVector AngularAcceleration = GetTorque()
									- AngularVelocity * AngularDrag;

		AngularVelocity += AngularAcceleration * DeltaTime;

		// Calculate Movement
		FVector TargetLocation = ActorLocation + Velocity * DeltaTime;
		
		TargetLocation.Z = FMath::Max(TargetLocation.Z, StreamLocation.Z);
		
		FVector DeltaMove = TargetLocation - ActorLocation;
		Velocity = DeltaMove / DeltaTime;

		// Lerp in AngularVelocity if LerpInWobbleTime is set
		if (LerpInWobbleTimer > 0)
		{
			LerpInWobbleTimer -= DeltaTime;

			float Alpha = 1 - FMath::Max(0.f, LerpInWobbleTimer) / LerpInWobbleTime;

			AngularVelocity *= Alpha;
		}

		FQuat Rotation = RotationPivot.ComponentQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);

		FRotator Rotator = Rotation.Rotator();

		Rotator = ActorTransform.InverseTransformRotation(Rotator);
		Rotator.Yaw = 0.f;

		// Move first! 
		FHazeFrameMovement FrameMove = MovementComponent.MakeFrameMovement(n"TreeBoatMovement");
		if (HasControl())
		{
			FrameMove.ApplyDelta(DeltaMove);
			FrameMove.SetRotation(Rotation);
			MovementComponent.Move(FrameMove);

			if (ImpactCooldownTimer > 0.f)
				ImpactCooldownTimer -= DeltaTime;

			// Do Impacts
			if (MovementComponent.ForwardHit.bBlockingHit)
				DoImpact(MovementComponent.ForwardHit);

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MovementComponent.Move(FrameMove);
		}

		// ... then update the detached mesh to be where the movement took us
		//	plus the wibbly wobbly water rotations :) This will trigger players' MoveWithFloor

		FTransform RelativeTransform;
		RelativeTransform.Rotation = Rotator.Quaternion();

		RotationPivot.SetWorldTransform(RelativeTransform * WorldCollision.WorldTransform);
	}

	UFUNCTION(BlueprintEvent)
	void AddSapThrust(FVector Direction)
	{
		SapThrottleForce = -Direction * SapThrottlePower;
		SapThrottleForce = SapThrottleForce.ConstrainToPlane(ActorUpVector);
	}

	UFUNCTION()
	void DoImpact(FHitResult Hit)
	{
		// Bounce
		Velocity += Hit.Normal * FMath::Max( -(1.f + Restitution) * Velocity.DotProduct(Hit.Normal), 0.f);

		// Spin
		SetAngularVelocityFromImpact(Hit.ImpactPoint, 0.5f);

		if (ImpactCooldownTimer <= 0.f)
		{
			ImpactCooldownTimer = ImpactCooldown;

			float ImpactStrength = (Velocity.Size() > ImpactDamageThreshold && Velocity.GetSafeNormal().DotProduct(Hit.Normal) > 0.5) ? 2.f : 1.f;

			ImpactTreeBoat(Hit.ImpactPoint, ImpactStrength);
		}
	}

	UFUNCTION(BlueprintCallable)
	void ImpactTreeBoat(FVector ImpactLocation = FVector::ZeroVector, float ImpactStrength = 1.f, bool bAddSpin = false, FVector ImpactImpulse = FVector::ZeroVector, AActor ImpactingActor = nullptr)
	{
		if (!HasControl())
			return;

		Velocity += ImpactImpulse;
	
		if (bAddSpin)
			SetAngularVelocityFromImpact(ImpactLocation, 1.f);

		FVector ImpactVector = (RotationPivot.WorldLocation - ImpactLocation).GetSafeNormal() * ImpactStrength;
		
		FHazeDelegateCrumbParams ImpactCrumbParams;
		ImpactCrumbParams.AddVector(n"ImpactVector", ImpactVector);
		ImpactCrumbParams.AddObject(n"ImpactActor", ImpactingActor);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_TreeBoatImpact"), ImpactCrumbParams);					
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void DestroyTreeBoat()
	{
		Niagara::SpawnSystemAtLocation(DeathEffect, RotationPivot.WorldLocation, RotationPivot.WorldRotation);
		OnTreeBoatDestroyed.Broadcast(this);
	}

	UFUNCTION()
	void SetAngularVelocityFromImpact(FVector ImpactLocation, float Strength)
	{
		FVector HitAngularVelocity = Velocity.CrossProduct(ImpactLocation - RotationPivot.WorldLocation) / (TAU * TreeBoatRadius * 100.f);

		FVector ConstrainedHitAngularVelocity = HitAngularVelocity.ConstrainToDirection(WaterUp);

		AngularVelocity = ConstrainedHitAngularVelocity * Strength;
	}

	UFUNCTION()
	void UpdateSplashes(float DeltaTime)
	{
		// Boat Velocity Splashes
		float WaterSpawnRate = FMath::Min(Velocity.Size(), 3000.f);

		WaterNiagaraComponent.SetWorldRotation(FRotator::MakeFromZX(RotationPivot.UpVector, Velocity.GetSafeNormal()));
		WaterNiagaraComponent.SetNiagaraVariableFloat("SpawnRate", WaterSpawnRate * 0.1f);
		WaterNiagaraComponent.SetNiagaraVariableVec2("MinSize", FVector2D(WaterSpawnRate * 0.1f, WaterSpawnRate * 0.1f));
		WaterNiagaraComponent.SetNiagaraVariableVec2("MaxSize", FVector2D(WaterSpawnRate * 0.4f, WaterSpawnRate * 0.4f));

		FVector SplashDirection = (RotationPivot.UpVector * 100.f).ConstrainToPlane(WaterUp);
	//	System::DrawDebugLine(RotationPivot.WorldLocation + (RotationPivot.UpVector * 200.f), RotationPivot.WorldLocation + (RotationPivot.UpVector * 200.f) + SplashDirection * 100.f, FLinearColor::Yellow, 0.f, 20.f);

		FVector SplashLocation = RotationPivot.WorldLocation + SplashDirection.GetSafeNormal() * TreeBoatRadius;
		FRotator SplashRotation = FRotator::MakeFromZX(RotationPivot.UpVector, SplashDirection);
	
		SplashNiagaraComponent.SetWorldRotation(SplashRotation);
	//	SplashNiagaraComponent.SetWorldLocationAndRotation(SplashLocation, SplashRotation);

		SplashVelocity = (SplashDirection - LastSplashDirection) / DeltaTime;

		float SplashSpawnRate = FMath::Min(SplashVelocity.Size(), 100.f);	

		PrintToScreen("Splash: " + SplashSpawnRate, 0.f, FLinearColor::Green);
		PrintToScreen("Velocity: " + WaterSpawnRate, 0.f, FLinearColor::Green);

		// Detect Heavy Splash Event
		if (SplashSpawnRate > 80.f)
		{
			OnTreeBoatBigSplash.Broadcast(SplashSpawnRate);
		}

		if (SplashSpawnRate > 20.f)
		{
		//	System::DrawDebugLine(RotationPivot.WorldLocation + (RotationPivot.UpVector * 200.f), RotationPivot.WorldLocation + (RotationPivot.UpVector * 200.f) + SplashVelocity * 100.f, FLinearColor::Yellow, 0.f, 20.f);
			SplashNiagaraComponent.SetNiagaraVariableFloat("SpawnRate", SplashSpawnRate * 2.f);
			SplashNiagaraComponent.SetNiagaraVariableFloat("MinAngle", 0.4f);
			SplashNiagaraComponent.SetNiagaraVariableFloat("MaxAngle", 0.1f);
			SplashNiagaraComponent.SetNiagaraVariableVec2("MinSize", FVector2D(SplashSpawnRate * 10.f, SplashSpawnRate * 10.f));
			SplashNiagaraComponent.SetNiagaraVariableVec2("MaxSize", FVector2D(SplashSpawnRate * 30.f, SplashSpawnRate * 30.f));
		}
		else
		{
			SplashNiagaraComponent.SetNiagaraVariableFloat("SpawnRate", 0.f);
		}

		LastSplashDirection = SplashDirection;
	}

	UFUNCTION()
	void UpdateAudio(float DeltaTime)
	{
		float MappedYawSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 2.f), FVector2D(0.f, 1.f), MovementComponent.RotationDelta / DeltaTime);
		float MappedVelocity = FMath::GetMappedRangeValueClamped(FVector2D(0.f, SapThrottlePower), FVector2D(0.f, 1.f), MovementComponent.Velocity.Size());
		float MappedSplashes = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 100.f), FVector2D(0.f, 1.f), SplashVelocity.Size());
		float MappedTilt = FMath::GetMappedRangeValueClamped(FVector2D(0.95f, 1.f), FVector2D(1.f, 0.f), RotationPivot.UpVector.DotProduct(FVector::UpVector));
		
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_TreeBoat_Tilt", MappedTilt);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_TreeBoat_SplashAmount", MappedSplashes);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_TreeBoat_Velocity", MappedVelocity);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_TreeBoat_AngularVelocity", MappedYawSpeed);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_TreeBoat_AngVeloCombined", FMath::Max(MappedVelocity, MappedYawSpeed));
	}

	UFUNCTION()
	void OnWorldCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		ATreeBoatForceVolume ForceVolume = Cast<ATreeBoatForceVolume>(OtherActor);
		if (ForceVolume != nullptr)
		{
			if (ForceVolumeGroups.Contains(ForceVolume.Group))
				ForceVolumeGroups[ForceVolume.Group].ForceVolumes.Add(ForceVolume);
			else
				ForceVolumeGroups.Add(ForceVolume.Group, FTreeBoatForceVolumesArray(ForceVolume));
		}
	}

	UFUNCTION()
	void OnWorldCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		ATreeBoatForceVolume ForceVolume = Cast<ATreeBoatForceVolume>(OtherActor);
		if (ForceVolume != nullptr)
		{
			if (ForceVolumeGroups.Contains(ForceVolume.Group))
				ForceVolumeGroups[ForceVolume.Group].ForceVolumes.Remove(ForceVolume);
			if (ForceVolumeGroups[ForceVolume.Group].ForceVolumes.Num() == 0)
				ForceVolumeGroups.Remove(ForceVolume.Group);
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetVolumeForce()
	{
		FVector TreeBoatForceVolumeForce;
		FLinearColor DebugColor;

		for (auto Group : ForceVolumeGroups)
		{
			FVector GroupForce = FVector::ZeroVector;

			for (auto ForceVolume : Group.Value.ForceVolumes)
			{
				GroupForce += ForceVolume.GetVolumeForce(WorldCollision);			
				DebugColor = ForceVolume.ArrowColor;
			}

			GroupForce /= Group.Value.ForceVolumes.Num();
			TreeBoatForceVolumeForce += GroupForce;

			if (bDrawDebug)
			{
				FVector ForceDirection = GroupForce;
				FVector LineStart = ActorLocation + (ActorUpVector * 130.f) + (ForceDirection.GetSafeNormal() * -TreeBoatRadius);
				FVector LineEnd = LineStart + ForceDirection * 0.5f;
				System::DrawDebugArrow(LineStart, LineEnd, 5000.f, DebugColor, 0.f, 30.f);
			}
		}
	
		return TreeBoatForceVolumeForce;
	}

	void GetLocationAndNormalFromTraces(FVector &OutLocation, FVector &OutNormal, float Radius = 100.f, int Traces = 6)
	{
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::Vehicle);

		TArray<AActor> ActorsToIgnore;

		FVector AverageLocation;
		FVector AverageNormal;

		TArray<FVector> LocationSamples;
		TArray<FVector> NormalSamples;

		float AngleStep = TAU / Traces;

		for (int i = 0; i < Traces; i++)
		{
			FVector RelativeTraceStart = FVector(FMath::Cos(i * AngleStep) * Radius, FMath::Sin(i * AngleStep) * Radius, 0.f);

			FVector TraceStart = RotationPivot.WorldTransform.TransformPosition(RelativeTraceStart) + FVector(0.f, 0.f, 1000.f);
			FVector TraceEnd = TraceStart + FVector(0.f, 0.f, -10000);

			if (bDrawDebug)
				System::DrawDebugSphere(TraceStart, 50.f, 12, FLinearColor::Green, 0, 20.f);

			FHitResult HitResult;

			if (System::LineTraceSingleForObjects(TraceStart, TraceEnd, ObjectTypes, true, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true, FLinearColor::Green, FLinearColor::Green, 0.f))
			{
				LocationSamples.Add(HitResult.Location);
				AverageLocation += HitResult.Location;
				if (bDrawDebug)
					System::DrawDebugSphere(HitResult.Location, 100.f, 12, FLinearColor::Green, 0, 20.f);
			}
		}

		for (int i = 0; i < LocationSamples.Num(); i++)
		{					
			FVector SampleNormal = (LocationSamples[Math::IWrap(i + 1, 0, LocationSamples.Num() - 1)] - LocationSamples[i]).CrossProduct((LocationSamples[Math::IWrap(i + 2, 0, LocationSamples.Num() - 1)] - LocationSamples[i]));
			AverageNormal += SampleNormal;
		}

		if (LocationSamples.Num() == 0)
		{
			OutLocation = FVector::ZeroVector;
			OutNormal = FVector::ZeroVector;
			return;
		}

		OutLocation = (AverageLocation / LocationSamples.Num());
		OutNormal = (AverageNormal / LocationSamples.Num()).GetSafeNormal();
		
		if (bDrawDebug)
		{
			System::DrawDebugSphere(OutLocation, 100.f, 12, FLinearColor::Yellow, 0, 20.f);
			System::DrawDebugLine(OutLocation, OutLocation + OutNormal * 1000.f, FLinearColor::Blue, 0.f, 20.f);
		}
	}

	UFUNCTION()
	FVector GetPlayerTorque()
	{
		FVector PlayerBalanceVector;

		for (auto Player : Players)
		{
			PlayerBalanceVector += RotationPivot.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		}

		return PlayerBalanceVector * 0.5f; // added * 0.5f to lessen the tilt of the boat from player positioning
	}

	UFUNCTION()
	FVector GetSapThrottleTorque()
	{
		FVector SapThrottle = RotationPivot.WorldTransform.InverseTransformVector(SapThrottleForce) * 0.5f;

		SapThrottle *= FMath::Max(1.f - (Velocity.Size() / SapThrottlePower), 0.f);

		return SapThrottle;
	}

	UFUNCTION()
	FVector GetTorque()
	{
		FVector Balance = GetPlayerTorque() - GetSapThrottleTorque();

		Balance = RotationPivot.WorldTransform.TransformVector(Balance);

		FVector	LocalTorque;
	
		LocalTorque += WaterUp.CrossProduct(Balance) * 0.002f;
		LocalTorque += RotationPivot.UpVector.CrossProduct(WaterUp) * 20.f;

		LocalTorque = RotationPivot.WorldTransform.InverseTransformVector(LocalTorque);

		return LocalTorque;
	}	

	UFUNCTION()
	void CheckPlayerKillZone()
	{
		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsOverlappingActor(WaterLandscape) && !Player.IsOverlappingActor(this))
			{
				KillPlayer(Player, PlayerDeathEffect);
			}
/*
			FVector ToPlayer = (ActorLocation + ActorUpVector * -TreeBoatRadius) - Player.ActorLocation;

			if (ToPlayer.Size() < 10000.f && ToPlayer.GetSafeNormal().DotProduct(ActorUpVector) > 0.f)
			{
				KillPlayer(Player);
			}		
*/
		}
	}

	UFUNCTION()
	void AddHealthWidget()
	{
		TreeBoatHealthWidget = Cast<UTreeBoatHealthWidget>(Widget::AddFullscreenWidget(TreeBoatHealthWidgetClass));
		HealthPercent = RecentHealth = LastRecentHealth = TreeBoatHealth / TreeBoatMaxHealth;
		RecentDamageTimer = 0.f;
	}

	UFUNCTION()
	void RemoveHealthWidget()
	{
		if (TreeBoatHealthWidget == nullptr)
			return;

		Widget::RemoveFullscreenWidget(TreeBoatHealthWidget);
		TreeBoatHealthWidget = nullptr;
	}

	UFUNCTION()
	void UpdateHealthWidget(float DeltaTime)
	{
		if (TreeBoatHealthWidget == nullptr)
			return;

		HealthPercent = TreeBoatHealth / TreeBoatMaxHealth;
		RecentDamageTimer -= DeltaTime;
		if (RecentDamageTimer < 0.f)
		{
			LastRecentHealth = HealthPercent;

			if(!bHasTriggeredAudioRegen && bDidTakeDamage)
			{
				SetCapabilityActionState(n"AudioStartDecayHealth", EHazeActionState::ActiveForOneFrame);
				bHasTriggeredAudioRegen = true;
				bDidTakeDamage = false;
			}
		}

		RecentHealth = FMath::FInterpTo(RecentHealth, LastRecentHealth, DeltaTime, 12.f);
		
		if(FMath::IsNearlyEqual(RecentHealth, LastRecentHealth, 0.01f) && bHasTriggeredAudioRegen)
		{
			SetCapabilityActionState(n"AudioStopDecayHealth", EHazeActionState::ActiveForOneFrame);
			bHasTriggeredAudioRegen = false;
		}

		TreeBoatHealthWidget.HealthPercent = HealthPercent;
		TreeBoatHealthWidget.RecentHealth = RecentHealth;
	}

	UFUNCTION()
	void DrawDebug()
	{
		for (auto Group : ForceVolumeGroups)
		{
			for (auto ForceVolume : Group.Value.ForceVolumes)
			{
				PrintToScreen("Volumes: " + ForceVolume.Name + " in group: " + ForceVolume.Group, 0.f, ForceVolume.ArrowColor);
				FVector ForceDirection = ForceVolume.GetVolumeForce(WorldCollision);
				FVector LineStart = ActorLocation + (ActorUpVector * 100.f) + (ForceDirection.GetSafeNormal() * -TreeBoatRadius);
				FVector LineEnd = LineStart + ForceDirection * 0.5f;
				System::DrawDebugArrow(LineStart, LineEnd, 5000.f, ForceVolume.ArrowColor, 0.f, 30.f);
			}
		}

		for (auto Player : Players)
		{
			PrintToScreen("Player: " + Player.Name);
		}

		PrintToScreen("SplashVelocity: " + SplashVelocity.Size());
	}

	UFUNCTION()
	void UpdateDamageMesh()
	{
		float DamageAlpha = 1 - TreeBoatHealth / TreeBoatMaxHealth;

		int DamageMeshIndex = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.0), FVector2D(0, DamageMeshes.Num()), DamageAlpha);

		PrintToScreen("DamageAlpha: " + DamageAlpha + " DamageMeshIndex: " + DamageMeshIndex, 3.f);

		if (DamageMeshes.IsValidIndex(DamageMeshIndex))
			TreeBoatMeshComponent.SetStaticMesh(DamageMeshes[DamageMeshIndex]);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_TreeBoatImpact(const FHazeDelegateCrumbData& CrumbData)
	{
		FVector ImpactVector = CrumbData.GetVector(n"ImpactVector");
		FVector ImpactLocation = ActorLocation - ImpactVector.GetSafeNormal() * TreeBoatRadius;
		float ImpactStrength = ImpactVector.Size();

		AActor ImpactActor = Cast<AActor>(CrumbData.GetObject(n"ImpactActor"));

	//	System::DrawDebugSphere(ImpactLocation, ImpactStrength * 300.f, 12, FLinearColor::Red, 1.f, 10.f);
		Print("ImpactStrength: " + ImpactStrength, 1.f);

		HazeAkComp.HazePostEvent(AudioEvent_Impact);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_TreeBoat_CollisionForce", ImpactStrength);

		if (ImpactStrength >= 2.f)
		{
			Niagara::SpawnSystemAtLocation(HeavyImpactEffect, ImpactLocation);

			for (auto Player : Game::GetPlayers())
			{
				Player.PlayWorldCameraShake(ImpactCameraShakeClass, ActorLocation, TreeBoatRadius, TreeBoatRadius * 10.f, 1.f, 10.f, false, EHazeWorldCameraShakeSamplePosition::Player);
			}

			OnTreeBoatImpact.Broadcast(this, ImpactActor);
		
			RecentDamageTimer = 0.8f;

			float Damage = ImpactStrength - 1.f;

			if (!bIndestructible && Game::GetMay().GetGodMode() != EGodMode::God)
				TreeBoatHealth -= Damage;

			/* DAMAGE MESH */
			UpdateDamageMesh();

			if (TreeBoatHealth <= 0.f)
				DestroyTreeBoat();
			
			bDidTakeDamage = true;
		}
		else
		{
			Niagara::SpawnSystemAtLocation(LightImpactEffect, ImpactLocation);
		}
	
	}

}