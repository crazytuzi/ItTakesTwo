import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarActor;
import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureTugOfWar;

class UTugOfWarCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::ActiveGameplay);
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureTugOfWar MayAnimFeature;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureTugOfWar CodyAnimFeature;

	ATugOfWarActor ActiveInteraction;
	UTugOfWarManagerComponent ManagerComp;
	AHazePlayerCharacter Player;
	bool bEnterCompleted = false;
	bool bBothPlayersInteracting = false;

	FTimerHandle EnableCancelTimer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ActiveInteraction = Cast<ATugOfWarActor>(GetAttributeObject(n"TugOfWarActor"));
		ManagerComp = Cast<UTugOfWarManagerComponent>(GetAttributeObject(n"ManagerComp"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ActiveInteraction == nullptr)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveInteraction == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);

		Player.TriggerMovementTransition(Instigator = this);

		if(IsActioning(n"TugOfWarPlayer1"))
		{
			Player.SetActorLocation(ActiveInteraction.LeftAttachPoint.RelativeLocation);
			Player.SetActorRotation(ActiveInteraction.LeftAttachPoint.RelativeRotation);
			Player.AttachToComponent(ActiveInteraction.LeftAttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
		}
		else if(IsActioning(n"TugOfWarPlayer2"))
		{
			Player.SetActorLocation(ActiveInteraction.RightAttachPoint.RelativeLocation);
			Player.SetActorRotation(ActiveInteraction.RightAttachPoint.RelativeRotation);
			Player.AttachToComponent(ActiveInteraction.RightAttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
		}

		if(Player.IsCody())
		{
			Player.AddLocomotionFeature(CodyAnimFeature);
		}
		else
		{
			Player.AddLocomotionFeature(MayAnimFeature);
		}

		EnableCancelTimer = System::SetTimer(this, n"EnterFinished", 1.0f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.StopAllSlotAnimations();

		if(Player.IsCody())
		{
			Player.RemoveLocomotionFeature(CodyAnimFeature);
		}
		else
		{
			Player.RemoveLocomotionFeature(MayAnimFeature);
		}

		if(IsActioning(n"TugOfWarPlayer1"))
		{
			Player.SetCapabilityActionState(n"TugOfWarPlayer1", EHazeActionState::Inactive);
		}
		else if(IsActioning(n"TugOfWarPlayer2"))
		{
			Player.SetCapabilityActionState(n"TugOfWarPlayer2", EHazeActionState::Inactive);
		}

		ActiveInteraction.SetReadyForComplete(Player, false);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.SetCapabilityActionState(n"EnterFinished", EHazeActionState::Inactive);

		Player.DetachRootComponentFromParent();

		System::ClearAndInvalidateTimerHandle(EnableCancelTimer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData LocomotionRequestData;
		LocomotionRequestData.AnimationTag = n"TugOfWar";
		Player.RequestLocomotion(LocomotionRequestData);
	}

	UFUNCTION()
	void EnterFinished()
	{
		Player.SetCapabilityActionState(n"EnterFinished", EHazeActionState::Active);
	}

	UFUNCTION()
	void DisableCancel()
	{

	}
}