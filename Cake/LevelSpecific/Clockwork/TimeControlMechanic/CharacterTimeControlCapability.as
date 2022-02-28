import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.Movement.Components.MovementComponent;

// Amount of time after releasing all time control input before we stop controlling time
const float TIME_WITHOUT_INPUT_BEFORE_STOP = 0.5f;

class UCharacterTimeControlCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TimeControlCapabilityTags::TimeControlCapability);
	default CapabilityTags.Add(n"TimeControlling");
	default CapabilityTags.Add(n"BlockedWhileGrinding");

	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UTimeControlComponent TimeComp;
	UTimeControlActorComponent TargetedComponent;
	UHazeMovementComponent MoveComp;

	bool bHasPointOfInterese = false;
	float NoInputTimeLeft = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TimeComp = UTimeControlComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TimeComp.ForcedTimeControlComponent != nullptr)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			if (!MoveComp.IsGrounded())
				return EHazeNetworkActivation::DontActivate;

			UTimeControlActorComponent CurrentTargetComponent = TimeComp.GetCurrentTargetComponent();
			if (CurrentTargetComponent == nullptr)
				return EHazeNetworkActivation::DontActivate;
			
			if(!CurrentTargetComponent.bCanBeTimeControlled)
				return EHazeNetworkActivation::DontActivate;

			if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
				return EHazeNetworkActivation::DontActivate;
			
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (TimeComp.ForcedTimeControlComponent != nullptr)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (!MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		UTimeControlActorComponent CurrentTargetComponent = TimeComp.GetLockedOnComponent();
		if (CurrentTargetComponent == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (CurrentTargetComponent.IsTimeControlDisabled())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!CurrentTargetComponent.bCanBeTimeControlled)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// if (NoInputTimeLeft <= 0.f)
			// return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			// We can only cancel out after we no longer have a forced action
			if (CurrentTargetComponent.ForcedPlayerAction == ETimeControlPlayerAction::Nothing)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"TargetComp", TimeComp.GetCurrentTargetComponent());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetedComponent = Cast<UTimeControlActorComponent>(ActivationParams.GetObject(n"TargetComp"));
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"Grinding", this);
		TimeComp.ActivatedAbility(TargetedComponent, this);
		TimeComp.TimeControlBeamComponent.Activate();
		TimeComp.TimeControlBeamComponent.SetHiddenInGame(false);
		if (TargetedComponent.bAffectsCamera && !TargetedComponent.HasStaticCamera())
		{
			TimeComp.SetCameraSettingsEnabled(TargetedComponent, true);
			TimeComp.ApplyPoi(TargetedComponent);
		}

		TimeComp.SpawnedTimeControlWatch.AttachToActor(Game::GetCody(), n"LeftAttach");
		TimeComp.SpawnedTimeControlWatch.SetActorRelativeTransform(FTransform::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(n"Grinding", this);
		if (TargetedComponent.bAffectsCamera && !TargetedComponent.HasStaticCamera())
		{
			TimeComp.SetCameraSettingsEnabled(nullptr, false);
			TimeComp.ClearPoi();
		}
		Player.ClearCameraSettingsByInstigator(this, TargetedComponent.ControlCameraSettingsBlendOutTime);
		TargetedComponent.ChangePlayerAction(ETimeControlPlayerAction::Nothing);
		TimeComp.DeactiveAbility(this);
		TimeComp.TimeControlBeamComponent.Deactivate();
		TimeComp.TimeControlBeamComponent.SetHiddenInGame(true);

		TimeComp.SpawnedTimeControlWatch.AttachToActor(Game::GetCody(), n"Backpack");
		TimeComp.SpawnedTimeControlWatch.SetActorRelativeTransform(TimeComp.SpawnedTimeControlWatch.BackpackAttachOffset);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(HasControl())
		{
			NoInputTimeLeft -= DeltaTime;
			float RawDir = 0.f;

			float SecondaryValue = GetAttributeValue(AttributeNames::SecondaryLevelAbilityAxis);
			float PrimaryValue = GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis);

			FVector2D PlayerInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			float TimeControlValue = PlayerInput.Y;

			ETimeControlPlayerAction PlayerAction = ETimeControlPlayerAction::Nothing;
			if (TimeControlValue > 0.f)
			{
				PlayerAction = ETimeControlPlayerAction::ProgressTime;
				Player.SetFrameForceFeedback(0.f, 0.025f);
			}
			else if (TimeControlValue < 0.f)
			{
				PlayerAction = ETimeControlPlayerAction::ReverseTime;
				Player.SetFrameForceFeedback(0.025f, 0.f);
			}
			else
			{
				PlayerAction = ETimeControlPlayerAction::HoldTime;
			}

			// The target component might be forcing us to take a particular action
			if (TargetedComponent.ForcedPlayerAction != ETimeControlPlayerAction::Nothing)
			{
				PlayerAction = TargetedComponent.ForcedPlayerAction;
			}
			else
			{
				if (TimeControlValue > 0.f)
					PlayerAction = ETimeControlPlayerAction::ProgressTime;
				else if (TimeControlValue < 0.f)
					PlayerAction = ETimeControlPlayerAction::ReverseTime;
				else
					PlayerAction = ETimeControlPlayerAction::HoldTime;
			}

			if (PlayerAction == ETimeControlPlayerAction::ProgressTime)
				Player.SetFrameForceFeedback(0.f, 0.025f);
			else if (PlayerAction == ETimeControlPlayerAction::ReverseTime)
				Player.SetFrameForceFeedback(0.025f, 0.f);

			TargetedComponent.ChangePlayerAction(PlayerAction);	
		}
		
		if(TimeComp.LockedOnComponent != nullptr)
		{
			TimeComp.TimeWidget.CurrentArrowValue = TimeComp.LockedOnComponent.GetPointInTime();
		}
		
		TimeComp.UpdateBeamLocation(TargetedComponent);

		MoveComp.SetTargetFacingDirection(TimeComp.ActiveTimeControlTargetDirection, -1.f);
	}
}