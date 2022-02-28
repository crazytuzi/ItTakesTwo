import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Hopscotch.RopewayActor;
import Vino.Movement.Components.MovementComponent;

class URopewayCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RopewayCapability");
	default CapabilityDebugCategory = n"RopewayCapability";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UInteractionComponent InteractionComp;
	ARopewayActor RopewayActor;
	bool bCanceled = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (InteractionComp != nullptr)
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(InteractionComp == nullptr || bCanceled)
		    return EHazeNetworkDeactivation::DeactivateLocal;
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Movement", this);
		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);
		Player.AttachToComponent(InteractionComp);
		Player.AddLocomotionFeature(Game::GetMay() == Player ? RopewayActor.MayFeature : RopewayActor.CodyFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(n"Movement", this);
		RopewayActor.PlayerStoppedUsingRopeway(Player);
		Player.RemoveLocomotionFeature(Game::GetMay() == Player ? RopewayActor.MayFeature : RopewayActor.CodyFeature);
		Player.UnblockMovementSyncronization(this);
		bCanceled = false;
		if (GetAttributeNumber(n"RopewayFinished") == 1)
		{
			FHazeJumpToData JumpData;
			JumpData.Transform = Cast<AActor>(GetAttributeObject(n"RopewayJumpToActor")).GetActorTransform();
			JumpTo::ActivateJumpTo(Player, JumpData);
		}

		if (InteractionComp != nullptr)
		{
			RopewayActor.SetInteractionPointEnabled(InteractionComp);
			InteractionComp = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject Comp;
		if (ConsumeAttribute(n"RopewayInteractionComponent", Comp))
		{
			InteractionComp = Cast<UInteractionComponent>(Comp);
		}

		UObject Rope;
		if (ConsumeAttribute(n"RopewayActor", Rope))
		{
			RopewayActor = Cast<ARopewayActor>(Rope);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData LocoData;
		LocoData.AnimationTag = n"CoatHanger";
		Player.RequestLocomotion(LocoData);
		float Value = 1.f;
		Player.SetAnimFloatParam(n"CoatHangerSpeed", RopewayActor.BlendSpaceSpeed); 

		if (WasActionStarted(ActionNames::Cancel) && RopewayActor.DoubleInteract.CanPlayerCancel(Player))
			NetSetCanceled();
	}

	UFUNCTION(NetFunction)
	void NetSetCanceled()
	{
		bCanceled = true;
	}
}