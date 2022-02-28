import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Hopscotch.MouseRide;

class UMouseRideCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");

	default CapabilityDebugCategory = n"MouseRide";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UInteractionComponent InteractionComp;
	AMouseRide MouseRide;
	bool bCanceled = false;
	USceneComponent AttachComponent;

	UPROPERTY()
	UAnimSequence MayAnim;
	
	UPROPERTY()
	UAnimSequence CodyAnim;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (InteractionComp != nullptr)
			return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (InteractionComp == nullptr || bCanceled)
			return EHazeNetworkDeactivation::DeactivateLocal;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject Comp;
		if (ConsumeAttribute(n"InteractionComponent", Comp))
		{
			InteractionComp = Cast<UInteractionComponent>(Comp);
		}

		UObject Mouse;
		if (ConsumeAttribute(n"MouseRideActor", Mouse))
		{
			MouseRide = Cast<AMouseRide>(Mouse);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::TotemInput, this);
		AttachComponent = Cast<USceneComponent>(GetAttributeObject(n"AttachComponent"));
		Player.AttachToComponent(AttachComponent);
		Player.BlockMovementSyncronization(this);
		UAnimSequence AnimToPlay = Player == Game::GetCody() ? CodyAnim : MayAnim;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MouseRide.PlayerStoppedUsingMouseRide(Player);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::TotemInput, this);
		Player.UnblockMovementSyncronization(this);
		bCanceled = false;
		Player.StopAllSlotAnimations();

		if (InteractionComp != nullptr)
		{
			MouseRide.EnableInteractionPoint(Player);
			InteractionComp = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (WasActionStarted(ActionNames::Cancel) && MouseRide.DoubleInteract.CanPlayerCancel(Player))
		{
			NetSetCanceled();
		}
	}

	UFUNCTION(NetFunction)
	void NetSetCanceled()
	{
		bCanceled = true;
		MouseRide.EnableInteractionPoint(Player);
	}
}