import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilBeanstalk;

class UBeanstalkSpawnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityDebugCategory = n"Beanstalk";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	ABeanstalk Beanstalk;
	AHazePlayerCharacter OwnerPlayer;
	UControllablePlantsComponent PlantsComp;

	UHazeMovementComponent MovementComponent;
	UHazeCrumbComponent CrumbComp;
	UBeanstalkSettings Settings;

	ASubmersibleSoilBeanstalk SoilBeanstalk;

	FVector InitialCameraDirection;

	bool bFirstTutorialsShown = false;

	bool bSecondTutorialsShown = false;

	float TutorialTimer = 0.0f;

	float FirstTutorialDuration = 10.0f;
	float ShorterTutorialDuration = 5.0f;
	float SecondTutorialDuration = 10.0f;

	float OldMaxLength = 0.0f;
	float OldMaxHeight = 0.0f;
	float OldMinHeight = 0.0f;

	bool bFirstLeafPairHasBeenSpawned = false;
	bool bSpawnFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
		Settings = UBeanstalkSettings::GetSettings(Owner);
		OwnerPlayer = Beanstalk.OwnerPlayer;
		PlantsComp = UControllablePlantsComponent::Get(OwnerPlayer);
		MovementComponent = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Beanstalk.bBeanstalkActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddVector(n"SpawnFacingDirection", OwnerPlayer.ViewRotation.GetForwardVector().ConstrainToPlane(MovementComponent.WorldUp));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OldMaxLength = Beanstalk.BeanstalkMaxLength;
		OldMaxHeight = Beanstalk.MaxHeight;
		OldMinHeight = Beanstalk.MinHeight;

		InitialCameraDirection = ActivationParams.GetVector(n"SpawnFacingDirection");

		bSpawnFinished = false;
		Elapsed = 1.5f;
		bEnabledCollision = false;

		bSecondTutorialsShown = false;
		bFirstLeafPairHasBeenSpawned = false;
		Beanstalk.bHasExtended = false;

		FinishSpawningBeanstalk();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Beanstalk.bBeanstalkActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(OwnerPlayer, this);
		Owner.SetCapabilityActionState(BeanstalkTags::Active, EHazeActionState::Inactive);

		bFirstTutorialsShown = false;
		bSecondTutorialsShown = false;

		Beanstalk.bSpawningDone = false;
		Beanstalk.CleanupCurrentMovementTrail();

		Owner.SetActorHiddenInGame(true);
		//Owner.SetActorEnableCollision(false);
		Beanstalk.StopBlendSpace();

		if(SoilBeanstalk != nullptr)
		{
			SoilBeanstalk.EnableDeathVolumes();
		}

		Beanstalk.CurrentState = EBeanstalkState::Inactive;
	}

	float Elapsed = 0.0f;
	bool bEnabledCollision = false;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bSecondTutorialsShown && Beanstalk.bHasExtended)
		{
			TutorialTimer += DeltaTime;
			if(TutorialTimer >= (FirstTutorialDuration + 1.f) && bFirstLeafPairHasBeenSpawned)
			{
				RemoveTutorialPromptByInstigator(OwnerPlayer, this);

				FTutorialPrompt TriggerRevertPrompt;
				TriggerRevertPrompt.Action = ActionNames::SecondaryLevelAbility;
				TriggerRevertPrompt.Text = Beanstalk.Revert;
				TriggerRevertPrompt.MaximumDuration = SecondTutorialDuration;
				TriggerRevertPrompt.Mode = ETutorialPromptMode::Default;
				ShowTutorialPrompt(OwnerPlayer, TriggerRevertPrompt, this);

				bSecondTutorialsShown = true;
			}
			else if(!bFirstLeafPairHasBeenSpawned)
			{
				if(Beanstalk.LeafPairCollection.Num() > 0)
					bFirstLeafPairHasBeenSpawned = true;
			}
		}

		// Because we activate from control side but we want to wait until the remote side has finished entering the soil patch. 
		// Can't do local activation because we want to send a facing direction.
		if(Beanstalk.bBeanstalkActive && !bSpawnFinished)
		{
			bSpawnFinished = true;
			//FinishSpawningBeanstalk();
		}

		Elapsed -= DeltaTime;
	}

	private void FinishSpawningBeanstalk()
	{
		Beanstalk.bIsPlantActive = true;
		Beanstalk.bSpawningDone = true;
		
		FRotator TargetRotation = (InitialCameraDirection + MovementComponent.WorldUp).GetSafeNormal().ToOrientationRotator();
		FVector StartLocation = OwnerPlayer.ActorLocation;

		if(PlantsComp.ActivatingSoil != nullptr)
		{
			SoilBeanstalk = Cast<ASubmersibleSoilBeanstalk>(PlantsComp.ActivatingSoil.Owner);
			Beanstalk.BeanstalkSoil = SoilBeanstalk;
			StartLocation = SoilBeanstalk.SpawnLocation;
		}
		
		if(SoilBeanstalk != nullptr)
		{
			Beanstalk.TopViewYawAngle = SoilBeanstalk.CameraYaw;

			if(SoilBeanstalk.bOverrideStartingLocation)
			{
				//StartLocation = SoilBeanstalk.OverrideStartingLocation;
			}

			SoilBeanstalk.DisableDeathVolumes();
		}

		TargetRotation.Pitch = 85.0f;

		//StartLocation = StartLocation - TargetRotation.Vector() * 200.0f;

		const FVector SegmentStartLocation = StartLocation;// - FVector(0.0f, 0.0f, 100.0f);
		Beanstalk.BeanstalkStartLocation = SegmentStartLocation;
		const FVector SpawnLocation = StartLocation;
		Owner.TeleportActor(SpawnLocation, FRotator::ZeroRotator);
		
		Beanstalk.HeadRotationNode.SetWorldRotation(TargetRotation);
		//Beanstalk.SetActorHiddenInGame(false);
		Beanstalk.ClearSplines();

		Beanstalk.BeanstalkRoot.SetActorLocation(SegmentStartLocation);
		Beanstalk.SplineComp.SetWorldLocation(SegmentStartLocation);
		Beanstalk.ReversalSplineComp.SetWorldLocation(SegmentStartLocation);
		Beanstalk.VisualSpline.SetWorldLocation(SegmentStartLocation);

		
		Beanstalk.SplineComp.AddSplinePoint(SegmentStartLocation, ESplineCoordinateSpace::World, false);
		
		Beanstalk.SplineComp.AddSplinePoint(SpawnLocation, ESplineCoordinateSpace::World, false);
		Beanstalk.SplineComp.AddSplinePoint(Beanstalk.BeanstalkHead.GetSocketLocation(n"Jaw"), ESplineCoordinateSpace::World, false);
		Beanstalk.AddSplineMesh();
		Beanstalk.AddSplineMesh();
		
		//Beanstalk.AddSplineMesh();
		//Beanstalk.CurrentVelocity = Settings.InitialVelocity;

		Beanstalk.SplineComp.UpdateSpline();
		Beanstalk.VisualSpline.CopyFromOtherSpline(Beanstalk.SplineComp);
		Owner.SetCapabilityActionState(BeanstalkTags::Active, EHazeActionState::Active);

		// Tutorial

		FTutorialPrompt MovementPrompt;
		MovementPrompt.Action = AttributeVectorNames::MovementRaw;
		MovementPrompt.Text = Beanstalk.Turn;
		MovementPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		MovementPrompt.MaximumDuration = 0;
		MovementPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(OwnerPlayer, MovementPrompt, this);

		FTutorialPrompt TriggerMovementPrompt;
		TriggerMovementPrompt.Action = ActionNames::PrimaryLevelAbility;
		TriggerMovementPrompt.Text = Beanstalk.Extend;
		TriggerMovementPrompt.MaximumDuration = 0;
		TriggerMovementPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(OwnerPlayer, TriggerMovementPrompt, this);

		FTutorialPrompt LeavesPrompt;
		LeavesPrompt.Action = ActionNames::BeanstalkSpawnLeaf;
		LeavesPrompt.Text = Beanstalk.GrowLeaves;
		LeavesPrompt.MaximumDuration = 0;
		LeavesPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(OwnerPlayer, LeavesPrompt, this);

		bFirstTutorialsShown = true;

		if(!bFirstLeafPairHasBeenSpawned)
			FirstTutorialDuration = ShorterTutorialDuration;

		if(Beanstalk.AppearAnim != nullptr)
		{
			FHazePlaySlotAnimationParams Params;
			Params.Animation = Beanstalk.AppearAnim;
			Params.BlendTime = 0.0f;
			Params.BlendType = EHazeBlendType::BlendType_Crossfade;

			FHazeAnimationDelegate OnBlendOut;
			OnBlendOut.BindUFunction(this, n"Handle_AppearBlendOut");

			Beanstalk.BeanstalkHead.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendOut, Params);
		}

		Beanstalk.CurrentState = EBeanstalkState::Emerging;
		//Beanstalk.SetActorHiddenInGame(false);
		//Beanstalk.InputModifierElapsed = 1.0f;
	}

	UFUNCTION()
	private void Handle_AppearBlendOut()
	{
		Beanstalk.StartBlendSpace();
	}
}
