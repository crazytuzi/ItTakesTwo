import Cake.LevelSpecific.Shed.NailMine.LiftBlockActor;
import Peanuts.ButtonMash.ButtonMashHandleBase;
import Peanuts.ButtonMash.ButtonMashStatics;
import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Vino.Interactions.InteractionComponent;

class ULiftBlockCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LiftBlock");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LiftBlock";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ALiftBlockActor LiftBlock;

	FVector ButtonMashLocation;

	UButtonMashProgressHandle ButtonMash;

	UInteractionComponent ButtonMashPositionComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"LiftBlockActor") != nullptr)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetAttributeObject(n"LiftBlockActor") == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LiftBlock = Cast<ALiftBlockActor>(GetAttributeObject(n"LiftBlockActor"));
		ButtonMashPositionComp = Cast<UInteractionComponent>(GetAttributeObject(n"ButtonMashPosition"));
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		ButtonMash = StartButtonMashProgressAttachToComponent(Player, ButtonMashPositionComp, n"", FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (ButtonMashPositionComp == LiftBlock.InteractionPoint)
			LiftBlock.InteractingPlayerCancel();
		else
			LiftBlock.OtherSideInteractingPlayerCancel();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		StopButtonMash(ButtonMash);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (ButtonMashPositionComp == LiftBlock.InteractionPoint)
			LiftBlock.FirstInteractionButtonMashRate = ButtonMash.MashRateControlSide;
		
		else
			LiftBlock.SecondInteractionButtonMashRate = ButtonMash.MashRateControlSide;
			
		ButtonMash.Progress = LiftBlock.PositionAlpha;
	}
}