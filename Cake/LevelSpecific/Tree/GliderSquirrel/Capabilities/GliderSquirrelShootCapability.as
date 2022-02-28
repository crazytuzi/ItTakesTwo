import Cake.LevelSpecific.Tree.GliderSquirrel.GliderSquirrel;
import Cake.LevelSpecific.Tree.Escape.EscapeManager;

class UGliderSquirrelShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GliderSquirrel");
	default CapabilityTags.Add(n"GliderSquirrelShoot");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 51;

	AGliderSquirrel Squirrel;
	AFlyingMachine Target;

	float ShootTimer = 0.f;
	bool bShootRightMuzzle = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AGliderSquirrel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Squirrel.IsDead())
			return EHazeNetworkActivation::DontActivate;

		if (Squirrel.bShouldHoldFire)
			return EHazeNetworkActivation::DontActivate;

		if (ShootTimer > 0.f)
			return EHazeNetworkActivation::DontActivate;

		// Are we actually looking at the target?
		FVector TargetLoc = Squirrel.Target.GetActorLocation();
		FVector DirectionToTarget = TargetLoc - Squirrel.GetActorLocation();
		DirectionToTarget.Normalize();

		FVector Forward = Squirrel.GetActorForwardVector();
		if (DirectionToTarget.DotProduct(Forward) < 0.9f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Target = Squirrel.Target;
		ensure(Target != nullptr);

		FVector Origin = Squirrel.GetMuzzle(bShootRightMuzzle).WorldLocation;
		FVector Direction = Target.GetActorLocation() - Squirrel.GetActorLocation();
		Direction.Normalize();

		auto Projectile = SpawnEscapeSquirrelProjectile(Squirrel.ProjectileClass, Origin, Direction, Squirrel.CurrentVelocity);

		// No projectile means the pool has no available ones to spawn, so just get out
		if (Projectile == nullptr)
			return;

		ShootTimer = 0.2f / Squirrel.ShootFrequencyScale;
		Squirrel.BP_OnFire(bShootRightMuzzle);

		bShootRightMuzzle = !bShootRightMuzzle;
		Squirrel.PulseIndicatorWidget();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		ShootTimer -= DeltaTime;
	}
}