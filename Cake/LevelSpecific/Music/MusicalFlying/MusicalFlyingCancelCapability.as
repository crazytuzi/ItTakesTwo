import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

UCLASS(Deprecated)
class UMusicalFlyingCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 0;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		if (FlyingComp.CurrentState == EMusicalFlyingState::Inactive)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(n"PreventCancelFlying"))
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
		
		if(FlyingComp.PreventCancelTimeElapsed > 0.0f)
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}

		FHitResult Hit;
		if(MoveComp.LineTraceGround(Owner.ActorLocation, Hit))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if (WasActionStarted(ActionNames::Cancel))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(n"CymbalShield", this);
		
		// TODO: Keep these in to temporary play correct animations until rewrite of the physics is done.

		//Player.BlockCapabilities(MovementSystemTags::AirMovement, this);
		//Player.BlockCapabilities(CapabilityTags::Movement, this);

		UHazeLocomotionStateMachineAsset LocomotionStateMachine = Player.IsCody() ? FlyingComp.CodyFlyingStateMachine : FlyingComp.MayFlyingStateMachine;
		Player.AddLocomotionAsset(LocomotionStateMachine, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(ActionNames::MovementGroundPound);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(n"CymbalShield", this);

		// TODO: Keep these in to temporary play correct animations until rewrite of the physics is done.
		//Player.UnblockCapabilities(MovementSystemTags::AirMovement, this);
		//Player.UnblockCapabilities(CapabilityTags::Movement, this);

		FlyingComp.SetFlyingState(EMusicalFlyingState::Inactive);
		
		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

		if(CymbalComp != nullptr)
		{
			CymbalComp.BackSocket = n"Backpack";
			CymbalComp.AttachCymbalToBack();
			CymbalComp.UnblockCatchAnimation();
		}

		FlyingComp.bWasHovering = false;
		
		Player.StopBlendSpace();
		FlyingComp.OnExitFlying();

		Player.ClearLocomotionAssetByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FlyingComp.PreventCancelTimeElapsed -= DeltaTime;
	}
}
