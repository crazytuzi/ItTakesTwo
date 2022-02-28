import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Rice.Math.MathStatics;
import Vino.Movement.Swinging.SwingRope;

// Used for when attaching or detaching a rope
class USwingAttachCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingAttach");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 175;

	AHazePlayerCharacter OwningPlayer;
	USwingingComponent SwingingComponent;
	UCharacterAirJumpsComponent AirJumpsComp;
	UHazeAkComponent HazeAKComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
		HazeAKComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStartedDuringTime(n"SwingAttach", 0.1f))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (SwingingComponent.GetTargetSwingPoint() == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SwingingComponent.ActiveSwingPoint == SwingingComponent.GetTargetSwingPoint())
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"SwingPoint", SwingingComponent.GetTargetSwingPoint());
		// Start local checks and start local anims for 'build up' to hikde activation
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"SwingAttach");

		Owner.BlockCapabilities(MovementSystemTags::Grinding, this);

		// Update the active swing point
		USwingPointComponent ActiveSwingPoint = Cast<USwingPointComponent>(ActivationParams.GetObject(n"SwingPoint"));

		if (SwingingComponent.ActiveSwingPoint != nullptr)
			SwingingComponent.StopSwinging();

		SwingingComponent.StartSwinging(ActiveSwingPoint);

		if (SwingingComponent.SwingRope != nullptr)
		{
			SwingingComponent.SwingRope.AttachToComponent(OwningPlayer.Mesh, SwingingComponent.SwingAttachSocketName);
			SwingingComponent.SwingRope.AttachToSwingPoint(ActiveSwingPoint);
		}

		AirJumpsComp.ResetJumpAndDash();

		ActiveSwingPoint.OnSwingPointAttached.Broadcast(OwningPlayer);
		SwingingComponent.OnAttachedToSwingPoint.Broadcast(ActiveSwingPoint);

		if (SwingingComponent.AttachForceFeedback != nullptr)
			OwningPlayer.PlayForceFeedback(SwingingComponent.AttachForceFeedback, false, true, n"SwingAttach");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Grinding, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsDebugActive())
			System::DrawDebugLine(Owner.ActorLocation, SwingingComponent.ActiveSwingPoint.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";

			DebugText += "Active Swing Point = ";
			DebugText += "" + SwingingComponent.ActiveSwingPoint.Name;

			return DebugText;
		}

		return "Not Active";
	}

}

UFUNCTION()
void ForceStopSwinging(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;
	USwingingComponent SwingComp = USwingingComponent::Get(Player);
	if (SwingComp == nullptr)
		return;

	Player.SetCapabilityActionState(n"ForceSwingDetach", EHazeActionState::ActiveForOneFrame);
}
