import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

class UFlyingMachineImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

	// Settings
	FFlyingMachineSettings Settings;

	// Last collision to be procssed
	FHitResult LastHit;

	// Timer of the collision recoil
	float Timer;

	// Translation away from the collision
	FVector ImpactNormal;
	float ImpactForce = 0.f;

	// Rotation away from the collision
	FVector RotationAxis;
	float RotationAngle;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem ImpactSystem;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Machine = Cast<AFlyingMachine>(Owner);
		Machine.OnCollision.AddUFunction(this, n"HandleMachineCollision");
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleMachineCollision(FHitResult Hit)
	{
		LastHit = Hit;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkActivation::DontActivate;

		if (!LastHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;

		if (LastHit.ImpactNormal.DotProduct(-Machine.Orientation.Forward) < 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Timer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(FlyingMachineTag::Boost, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(FlyingMachineTag::Boost, this);
	}

	void InitializeForHit(FHitResult Hit)
	{
		Timer = Settings.CollisionRecoilDuration;

		FVector Normal = LastHit.ImpactNormal;
		float Force = Normal.DotProduct(-Machine.ActorForwardVector);

		// We dont care if the normal is in the direction we're going already
		if (Force < 0.f)
			return;

		ImpactNormal = Normal;
		ImpactForce = Force;

		// Get the axis and angle of the recoil
		RotationAxis = Machine.Orientation.Forward.CrossProduct(ImpactNormal);
		RotationAxis.Normalize();
		RotationAngle = FMath::Lerp(Settings.CollisionRecoilMinAngle, Settings.CollisionRecoilMaxAngle, Force);

		Machine.CallOnImpactEvent(Hit);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LastHit.bBlockingHit)
		{
			// Process a new collision
			InitializeForHit(LastHit);
			LastHit = FHitResult();
		}

		Timer -= DeltaTime;
		float TimerPercent = Timer / Settings.CollisionRecoilDuration;

		// Move away from the collision
		if (HasControl())
			Machine.AddActorWorldOffset(ImpactNormal * Settings.CollisionRecoilVelocity * ImpactForce * TimerPercent * DeltaTime);

		// Rotate away from the collision
		float DeltaAngle = RotationAngle * DeltaTime * 5.f;
		RotationAngle -= DeltaAngle;
		FQuat DeltaQuat(RotationAxis, DeltaAngle * DEG_TO_RAD);

		FVector Forward = Machine.Orientation.Forward;
		Forward = DeltaQuat.RotateVector(Forward);

		Machine.Orientation.Forward = Forward;

		// Slow down speed
		float ForcePow = FMath::Pow(ImpactForce, 4.f);
		float SpeedLoss = Settings.MinSpeed - Machine.Speed;
		Machine.Speed += SpeedLoss * ForcePow;
	}
}