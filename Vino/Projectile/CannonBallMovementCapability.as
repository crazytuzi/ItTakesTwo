
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.Projectile.ProjectileMovement;

class UCannonBallMovementCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(n"CannonMovement");

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

    FProjectileMovementData ProjectileMovementData;

	// Internal Variables
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"CannonBallShoot"))
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ProjectileMovementData.Velocity = GetAttributeVector(n"CannonMovementVelocity");
        ProjectileMovementData.Gravity = 980.f;
		Player.SetCapabilityActionState(n"CannonBallShoot", EHazeActionState::Inactive);
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"Weapon", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Weapon", this);
		Player.SetCapabilityActionState(n"CannonBallShoot", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
        FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"CannonBallMovement");

        FProjectileUpdateData UpdateData = CalculateProjectileMovement(ProjectileMovementData, DeltaTime);
        MoveData.ApplyDelta(UpdateData.DeltaMovement);
		MoveData.ApplyTargetRotationDelta();
		ProjectileMovementData = UpdateData.UpdatedMovementData;
        MoveComp.Move(MoveData);
	}
};

UFUNCTION()
void StartCannonMovement(AHazePlayerCharacter Player, FVector Velocity)
{
    FProjectileMovementData Data;

    Data.Velocity = Velocity;
    Data.Gravity = 980.f;

	Player.SetCapabilityActionState(n"CannonBallShoot", EHazeActionState::Active);
	Player.SetCapabilityAttributeVector(n"CannonMovementVelocity", Velocity);
    Player.AddCapability(UCannonBallMovementCapability::StaticClass());

}
