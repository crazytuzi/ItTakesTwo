import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingComponent;
class USnowGlobeClimbingGripCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 105;

	USnowGlobeClimbingComponent ClimbingComponent;
	AHazePlayerCharacter Player;

	FHazeAcceleratedVector MoveToGrip;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		ClimbingComponent = USnowGlobeClimbingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(WasActionStarted(ActionNames::MovementJump))
			if(!MoveComp.IsGrounded())
				if(ClimbingComponent.GetGrip() != nullptr)
					return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!System::IsValid(ClimbingComponent.PlayerGripComponent))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ClimbingComponent.PlayerGripComponent.bGrippable)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ClimbingComponent.bHasGrip)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveToGrip.Value = Player.GetActorCenterLocation();
		MoveToGrip.Velocity = MoveComp.GetVelocity();

		ClimbingComponent.bHasGrip = true;
		ClimbingComponent.bCanJump = true;
		ClimbingComponent.PlayerGripComponent.OnGripBegin.Broadcast(Player);
		ClimbingComponent.PlayerMagneticComponent.bIsAnchored = true;

		Player.BlockCapabilities(n"SplineLock", this);

		Niagara::SpawnSystemAtLocation(ClimbingComponent.GripEffect, Player.GetActorCenterLocation());
	
		// Attach the Player?
		//Player.AttachToActor(ParentActor = ClimbingComponent.PlayerGripComponent.Owner, SocketName = NAME_None, AttachmentRule = EAttachmentRule::KeepWorld);
		//Player.SetActorLocation(Player.GetActorCenterLocation() - Player.GetActorLocation());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClimbingComponent.bHasGrip = false;
		ClimbingComponent.bCanJump = false;
		ClimbingComponent.PlayerMagneticComponent.bIsAnchored = false;
		ClimbingComponent.PlayerGripComponent.OnGripEnd.Broadcast(Player);
		ClimbingComponent.PlayerGripComponent = nullptr;

		Player.UnblockCapabilities(n"SplineLock", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//FMath::VInterpTo(Player.GetActorLocation(), ClimbingComponent.GripHitData.ImpactPoint, DeltaTime, 3.f);

		FVector GripTarget = ClimbingComponent.GripHitData.ImpactPoint + ClimbingComponent.GripHitData.Normal * Player.CapsuleComponent.CapsuleRadius;

		MoveToGrip.AccelerateTo(GripTarget, 0.25f, DeltaTime);

		FRotator Rotation = Math::MakeRotFromX(-ClimbingComponent.GripHitData.Normal);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"GripMovement");

		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);
		FrameMove.OverrideGroundedState(EHazeGroundedState::Grounded); // So we can dash again
		FrameMove.ApplyVelocity(MoveToGrip.Velocity);
		FrameMove.SetRotation(Rotation.Quaternion());

		MoveCharacter(FrameMove, n"Climbing");
	}
}