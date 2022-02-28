import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;

class UWallWalkingAnimalPlayerLaunchPreviewCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 140;

	AHazePlayerCharacter Player;
	UWallWalkingAnimalComponent AnimalComp;
	AWallWalkingAnimalLaunchPreviewActor PreviewActor;
	int FrameCounter = 0;
	//float TimeSinceValidTrace = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AnimalComp = UWallWalkingAnimalComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(PreviewActor != nullptr)
		{
			PreviewActor.DestroyActor();
			PreviewActor = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AnimalComp.CurrentAnimal == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if(Time::GameTimeSeconds < AnimalComp.CurrentAnimal.LaunchCooldown)
        	return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

		if (AnimalComp.CurrentAnimal.ActiveTransitionType != EWallWalkingAnimalTransitionType::None)
			return EHazeNetworkActivation::DontActivate;

		if (!AnimalComp.CurrentAnimal.bValidSurface)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	// bool bDebugLock = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// DEBUG
		//return EHazeNetworkDeactivation::DontDeactivate;

		// DEBUG
		// if(bDebugLock)
		// 	return EHazeNetworkDeactivation::DontDeactivate;

		if(AnimalComp.CurrentAnimal == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (AnimalComp.CurrentAnimal.bLaunching)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (AnimalComp.CurrentAnimal.ActiveTransitionType != EWallWalkingAnimalTransitionType::None)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(ActionNames::WeaponAim, true);
		if(PreviewActor == nullptr)
		{
			PreviewActor = Cast<AWallWalkingAnimalLaunchPreviewActor>(SpawnActor(AnimalComp.CurrentAnimal.PreviewActorClass, Level = Owner.GetLevel()));
			PreviewActor.Mesh.SetRenderedForPlayer(Player.GetOtherPlayer(), false);
			PreviewActor.AttachToActor(AnimalComp.CurrentAnimal, NAME_None, EAttachmentRule::KeepWorld);
		}

		PreviewActor.SetActorHiddenInGame(false);
		FRotator PreviewRotation = Math::MakeRotFromXZ(AnimalComp.CurrentAnimal.GetMovementWorldUp(), AnimalComp.CurrentAnimal.GetActorForwardVector());
		PreviewActor.SetActorLocationAndRotation(AnimalComp.CurrentAnimal.GetActorLocation(), PreviewRotation);	
		PreviewActor.SetIsValid(false);

		AnimalComp.CurrentAnimal.bPreparingToLaunch = true;
		if(AnimalComp.LastAudioSpiderStandState != n"AudioSpiderStandUp")
		{
			AnimalComp.CurrentAnimal.SetCapabilityActionState(n"AudioSpiderStandUp", EHazeActionState::ActiveForOneFrame);
			AnimalComp.LastAudioSpiderStandState = n"AudioSpiderStandUp";
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(AnimalComp.CurrentAnimal.bLaunching)
		{
			DeactivationParams.AddActionState(n"Launching");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(ActionNames::WeaponAim, false);
		PreviewActor.SetActorHiddenInGame(true);
		
		if(AnimalComp.CurrentAnimal != nullptr)
		{
			AnimalComp.CurrentAnimal.ClearCeilingHitResult();
			AnimalComp.CurrentAnimal.bPreparingToLaunch = false;
			if(AnimalComp.LastAudioSpiderStandState != n"AudioSpiderStandDown")
			{
				AnimalComp.CurrentAnimal.SetCapabilityActionState(n"AudioSpiderStandDown", EHazeActionState::ActiveForOneFrame);
				AnimalComp.LastAudioSpiderStandState = n"AudioSpiderStandDown";
			}

			if(DeactivationParams.GetActionState(n"Launching"))
				AnimalComp.CurrentAnimal.bLaunching = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FrameCounter++;
		bool bCeilingIsValid = false;
		const FVector TraceAmount = AnimalComp.CurrentAnimal.MovementSettings.CeilingTraceAmount;

		const FVector WorldUp = AnimalComp.CurrentAnimal.MoveComp.WorldUp;
		FVector From = AnimalComp.CurrentAnimal.GetActorLocation();
		From += (WorldUp * AnimalComp.CurrentAnimal.GetCollisionSize().Y * 4);
		
		FVector TraceTo = From;
		TraceTo += (AnimalComp.CurrentAnimal.GetActorForwardVector() * TraceAmount.X);
		TraceTo += (AnimalComp.CurrentAnimal.GetActorRightVector() * TraceAmount.Y);
		TraceTo += WorldUp * TraceAmount.Z;

		float DebugTime = -1;
		if(IsDebugActive())
			DebugTime = 0;

		FHazeHitResult Ceiling;
		
		FHazeTraceParams Trace;
		Trace.InitWithMovementComponent(AnimalComp.CurrentAnimal.MoveComp);
		Trace.From = From;
		Trace.To = TraceTo;
		Trace.SetToSphere(AnimalComp.CurrentAnimal.GetCollisionSize().X * 1.15f);

	#if EDITOR
		if(IsDebugActive())
			Trace.DebugDrawTime = 0;
	#endif
	
		Trace.Trace(Ceiling);

        //AnimalComp.CurrentAnimal.MoveComp.LineTrace(From, TraceTo, Ceiling, DebugDraw = DebugTime);
	
		// We triggered the launch after 1 frame so all other capabilities can initialize
		const bool bWantToLaunch = WasActionStarted(ActionNames::MovementJump) && FrameCounter > 1;
		AnimalComp.CurrentAnimal.UpdateCeilingHitResult(Ceiling.FHitResult);

		if(Ceiling.bBlockingHit) 
		{	
			bCeilingIsValid = false;
			if(!Ceiling.bStartPenetrating && (Ceiling.Normal.DotProduct(WorldUp) < -0.5f))
			{
				bCeilingIsValid = true;
				if(!Ceiling.Component.HasTag(ComponentTags::GravBootsWalkable))
					bCeilingIsValid = false;

				else if(!Ceiling.Component.HasTag(ComponentTags::Walkable))
					bCeilingIsValid = false;
			}

			UpdatePreviewActor(Ceiling.FHitResult, bCeilingIsValid, DeltaTime);

			if(bWantToLaunch && bCeilingIsValid)
			{
				AnimalComp.CurrentAnimal.LaunchToCeiling(Ceiling.FHitResult);
			}
		}
		else
		{
			UpdatePreviewActor(Ceiling.FHitResult, false, DeltaTime);
		}
	}

	void UpdatePreviewActor(FHitResult Impact, bool bIsValid, float DeltaTime)
	{
		PreviewActor.SetIsValid(bIsValid);

		if(bIsValid)
		{
			FVector DirToImpact = Impact.ImpactPoint - AnimalComp.CurrentAnimal.GetActorLocation();
			if(DirToImpact.IsNearlyZero() || !bIsValid)
				DirToImpact = AnimalComp.CurrentAnimal.MoveComp.GetWorldUp();
			else
				DirToImpact.Normalize();

			FRotator PreviewRotation = Math::MakeRotFromXZ(DirToImpact, AnimalComp.CurrentAnimal.GetActorForwardVector());
			FVector LocationToSet = FMath::VInterpTo(PreviewActor.GetActorLocation(), Impact.Location, DeltaTime, 15.f);
			PreviewActor.SetActorLocationAndRotation(LocationToSet, PreviewRotation);	
		}
		else
		{
			
			FVector UpVector = AnimalComp.CurrentAnimal.GetWantedCameraWorldUp();
			FRotator PreviewRotation = Math::MakeRotFromXZ(UpVector, AnimalComp.CurrentAnimal.GetActorForwardVector());
			FVector LocationToSet = FMath::VInterpTo(PreviewActor.GetActorLocation(), Impact.TraceStart + (UpVector * 100.f), DeltaTime, 15.f);
			PreviewActor.SetActorLocationAndRotation(LocationToSet, PreviewRotation);		
		}
	}
}
