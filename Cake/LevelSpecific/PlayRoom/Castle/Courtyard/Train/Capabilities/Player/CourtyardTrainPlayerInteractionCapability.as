import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainUserComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureTrainRide;

class UCourtyardTrainPlayerInteractionCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCourtyardTrainUserComponent TrainComp;
	float FastScore = 0.f;

	bool bHandleAttached = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrainComp = UCourtyardTrainUserComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive())
			TrainComp.InteractionComp = Cast<UInteractionComponent>(GetAttributeObject(n"TrainInteraction"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (TrainComp.InteractionComp == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (GetAttributeObject(n"Train") == nullptr && GetAttributeObject(n"Carriage") == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bHandleAttached)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}	

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"TrainInteraction", TrainComp.InteractionComp);
		OutParams.AddObject(n"Train", GetAttributeObject(n"Train"));
		OutParams.AddObject(n"Carriage", GetAttributeObject(n"Carriage"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TrainComp.InteractionComp = Cast<UInteractionComponent>(GetAttributeObject(n"TrainInteraction"));
		TrainComp.Train = Cast<ACourtyardTrain>(GetAttributeObject(n"Train"));
		TrainComp.Carriage = Cast<ACourtyardTrainCarriageRidable>(GetAttributeObject(n"Carriage"));		

		bHandleAttached = false;
		FastScore = 0.f;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		Player.TriggerMovementTransition(Instigator = this);
		Player.AttachRootComponentTo(TrainComp.InteractionComp, AttachLocationType = EAttachLocation::SnapToTarget);

		ULocomotionFeatureTrainRide Feature;
		if (TrainComp.Carriage != nullptr)
		{
			Player.SetAnimBoolParam(n"InLocomotive", false);
			TrainComp.State = ECourtyardTrainState::Carriage;
			Feature = TrainComp.Carriage.PlayerFeatures[Player];

			if (Player.IsMay())
				PlayFoghornVOBankEvent(TrainComp.VOBank, n"FoghornDBPlayroomCastleTrainRidePassengerMay");
			else
				PlayFoghornVOBankEvent(TrainComp.VOBank, n"FoghornDBPlayroomCastleTrainRidePassengerCody");
		}
		else
		{
			Player.SetAnimBoolParam(n"InLocomotive", true);
			TrainComp.State = ECourtyardTrainState::Train;
			Feature = TrainComp.Train.PlayerFeatures[Player];

			// Only if train
			FTutorialPrompt Tutorial;
			Tutorial.Action = ActionNames::PrimaryLevelAbility;
			Tutorial.Text = NSLOCTEXT("CourtyardTrain", "Whistle", "Whistle");
			Tutorial.MaximumDuration = 4.f;
			Player.ShowTutorialPrompt(Tutorial, this);

		}

		Player.AddLocomotionFeature(Feature);

		FTutorialPrompt Tutorial;
		Tutorial.Text = NSLOCTEXT("CourtyardTrain", "ChangeCamera", "Change Camera");
		Tutorial.Action = ActionNames::InteractionTrigger;
		Tutorial.MaximumDuration = 4.f;
		Player.ShowTutorialPrompt(Tutorial, this);
	}

	UFUNCTION()
	void AttachHandle()
	{
		if (TrainComp.Carriage == nullptr)
			TrainComp.Train.WhistleHandle.AttachTo(Player.Mesh, n"RightAttach", EAttachLocation::SnapToTarget);

		ShowCancelPrompt(Player, this);

		bHandleAttached = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		RemoveCancelPromptByInstigator(Player, this);
		Player.RemoveTutorialPromptByInstigator(this);

		Player.ClearCameraSettingsByInstigator(this);

		TrainComp.bOnTrain = false;

		ULocomotionFeatureTrainRide Feature;
		if (TrainComp.Carriage != nullptr)
		{
			TrainComp.Carriage.CancelCarriageInteraction(Player, TrainComp.InteractionComp);
			Feature = TrainComp.Carriage.PlayerFeatures[Player];
		}
		else
		{
			TrainComp.Train.WhistleHandle.AttachToComponent(TrainComp.Train.WhistleSkeletalRoot);
			TrainComp.Train.WhistleHandle.RelativeLocation = FVector::ZeroVector;
			TrainComp.Train.WhistleHandle.RelativeRotation = FRotator::ZeroRotator;

			TrainComp.Train.CancelTrainInteraction(Player, TrainComp.InteractionComp);
			Feature = TrainComp.Train.PlayerFeatures[Player];
		}
		Player.RemoveLocomotionFeature(Feature);

		// Cleanup references
		UObject Object;
		ConsumeAttribute(n"Train", Object);
		ConsumeAttribute(n"Carriage", Object);
		ConsumeAttribute(n"TrainInteraction", Object);

		TrainComp.Train = nullptr;
		TrainComp.Carriage = nullptr;
		TrainComp.InteractionComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"TrainRide";
			Player.RequestLocomotion(Request);
		}

		float FastScoreTarget = 0.f;
		if (TrainComp.Carriage != nullptr)
		{
			float AngleScore = FMath::Pow(FMath::Clamp(TrainComp.Carriage.Angle / 32.5f, 0.f, 1.f), 1.8f);
			float SpeedScore = FMath::Pow(FMath::Clamp((TrainComp.Carriage.Speed - 450.f) / 800.f, 0.f, 1.f), 1.8f);
			FastScoreTarget = AngleScore + SpeedScore;
		}
		else
		{
			float AngleScore = FMath::Pow(FMath::Clamp(TrainComp.Train.Angle / 32.5f, 0.f, 1.f), 1.8f);
			float SpeedScore = FMath::Pow(FMath::Clamp((TrainComp.Train.CurrentSpeed - 450.f) / 800.f, 0.f, 1.f), 1.8f);
			FastScoreTarget = AngleScore + SpeedScore;
		}
		float InterpSpeed = FastScoreTarget > FastScore ? 2.25f : 0.5f;
		FastScore = FMath::FInterpTo(FastScore, FastScoreTarget, DeltaTime, InterpSpeed);

		bool bGoingFast = FastScore > 1.f;
		Player.SetAnimBoolParam(n"GoingFast", bGoingFast);

		if (!bHandleAttached && ActiveDuration >= 1.5f)
			AttachHandle();
	}
}