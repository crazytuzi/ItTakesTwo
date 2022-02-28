import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingBlade;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class UIceSkatingCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	// default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	USnowGlobeSwimmingComponent SwimmingComp;
	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;

	FIceSkatingSlopeSettings SlopeSettings;

	UClass PreviousCollisionSolverClass;
	UClass PreviousRemoteCollisionSolverClass;

	AIceSkatingBlade LeftBlade;
	AIceSkatingBlade RightBlade;

	FIceSkatingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		SwimmingComp = USnowGlobeSwimmingComponent::Get(Player);
		CrumbComp = UHazeCrumbComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (SkateComp.bForceEnter)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		FHitResult GroundHit = SkateComp.GetGroundHit();
		if (!IsSurfaceIceSkateable(GroundHit))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}
	
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		FHitResult GroundHit = SkateComp.GetGroundHit();

		if (GroundHit.bBlockingHit && !IsSurfaceIceSkateable(GroundHit))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsActioning(n"IsSwimming"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SkateComp.bIsIceSkating = true;

		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);
		Player.BlockCapabilities(MovementSystemTags::Crouch, this);
		Player.BlockCapabilities(n"GroundPoundJumpOnly", this);

		// Play initial landing animation if we entered from air
		if (MoveComp.BecameGrounded())
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");

		SkateComp.bForceEnter = false;
		SkateComp.CallOnIceSkatingStartedEvent();

		// Push our special ice skating collision solver
		MoveComp.GetCurrentCollisionSolverType(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);
		MoveComp.UseCollisionSolver(UIceSkatingCollisionSolver::StaticClass(), PreviousRemoteCollisionSolverClass);

		// Spawn trail components
		LeftBlade = Cast<AIceSkatingBlade>(SpawnActor(SkateComp.BladeClass, bDeferredSpawn = true));
//		LeftBlade.AttachToComponent(Player.Mesh, n"LeftFootSocketVFX", EAttachmentRule::SnapToTarget);
		LeftBlade.AttachToComponent(Player.Mesh, n"LeftFoot", EAttachmentRule::SnapToTarget);
		LeftBlade.Trail.MaxDecals = 15;
		LeftBlade.bIsRightFoot = false;
		LeftBlade.Player = Player;

		RightBlade = Cast<AIceSkatingBlade>(SpawnActor(SkateComp.BladeClass, bDeferredSpawn = true));
//		RightBlade.AttachToComponent(Player.Mesh, n"RightFootSocketVFX", EAttachmentRule::SnapToTarget);
		RightBlade.AttachToComponent(Player.Mesh, n"RightFoot", EAttachmentRule::SnapToTarget);
		RightBlade.Trail.MaxDecals = 15;
		RightBlade.bIsRightFoot = true;
		RightBlade.Player = Player;
		
		LeftBlade.FinishSpawningActor(FTransform());
		RightBlade.FinishSpawningActor(FTransform());

		Player.MeshOffsetComponent.OffsetRelativeWithTime(FVector::UpVector * Settings.SkateOffsetHeight, FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SkateComp.bIsIceSkating = false;
		CrumbComp.RemoveCustomParamsFromActorReplication(this);

		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);
		Player.UnblockCapabilities(MovementSystemTags::Crouch, this);
		Player.UnblockCapabilities(n"GroundPoundJumpOnly", this);

		// Revert back to the previous collision solver
		MoveComp.UseCollisionSolver(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);

		SkateComp.CallOnIceSkatingEndedEvent();

		LeftBlade.DestroyActor();
		RightBlade.DestroyActor();

		Player.MeshOffsetComponent.ResetWithTime();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SkateComp.CallOnTickEvent(DeltaTime);
	}
}
