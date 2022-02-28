import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;
import Cake.LevelSpecific.Shed.Main.WhackACody_May;
import Vino.Interactions.AnimNotify_Interaction;

//TODO:
// Add Additional VFX for Cody Hit.
//If disabling a turning hit, save Enum on comittment to atk, stop reading input for rotation/rotating while performing hit.

class UWhackACodyMayRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");
	default CapabilityTags.Add(n"WhackACodyRotate");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	UWhackACodyComponent WhackaComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this, n"WhackACody");
		Player.BlockMovementSyncronization(this);

		Player.AttachToComponent(WhackaComp.WhackABoardRef.MayAttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
		Player.AddLocomotionFeature(WhackaComp.MayAnimFeature);

		WhackaComp.CurrentDir = EWhackACodyDirection::Down;
		Player.RootComponent.RelativeRotation = DirToRotator(WhackaComp.CurrentDir);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockMovementSyncronization(this);
		Player.DetachRootComponentFromParent();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WhackaComp.HammerCooldown -= DeltaTime;
		WhackaComp.TurnCooldown -= DeltaTime;

		if (HasControl() && WhackaComp.TurnCooldown <= 0.f && WhackaComp.WhackABoardRef.MinigameState != EWhackACodyGameStates::ShowingTutorial)
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if (Input.SizeSquared() > 0.8f)
			{
				auto ClosestDir = WhackaComp.DirectionFromInput(Input);
				if (ClosestDir != WhackaComp.CurrentDir)
					NetSetNewDirection(ClosestDir);
			}
		}

		// Interp towards our current rotation
		FRotator CurrentRotation = Player.RootComponent.RelativeRotation;
		CurrentRotation = FMath::RInterpConstantTo(CurrentRotation, DirToRotator(WhackaComp.CurrentDir), DeltaTime, 1200.f);
		Player.RootComponent.RelativeRotation = CurrentRotation;

		// Animation request
		FHazeRequestLocomotionData LocomotionRequestData;
		LocomotionRequestData.AnimationTag = n"WhackACody";
		Player.RequestLocomotion(LocomotionRequestData);
	}

	UFUNCTION(NetFunction)
	void NetSetNewDirection(EWhackACodyDirection NewDir)
	{
		// Safety in case this is super delayed on remote side
		if (!IsActive())
			return;

		// Set animation bool param!
		// Get which direction we turned by calculating the difference between the two enums
		int Dif = int(NewDir) - int(WhackaComp.CurrentDir);
		Dif = Math::IWrap(Dif, 0, 4);

		FName ParamName = NAME_None;
		switch(Dif)
		{
			// Clockwise 90
			case 1:
				ParamName = n"bTurnRight";
				break;

			// Counter-clockwise 90
			case 3:
				ParamName = n"bTurnLeft";
				break;

			// Turning 180 degrees
			case 2:
				ParamName = n"bTurnBackwards";
				break;

			// 0 would mean turning to the same direction...
			// Shouldn't happen
		}

		Player.Mesh.SetAnimBoolParam(ParamName, true);
		WhackaComp.CurrentDir = NewDir;

		WhackaComp.HammerCooldown = 0.13f;
	}

	FRotator DirToRotator(EWhackACodyDirection Dir)
	{
		return FRotator(0.f, int(Dir) * 90.f, 0.f);
	}
}