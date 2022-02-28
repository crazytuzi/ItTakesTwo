import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;

class USnowTurtleRotationCorrectionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowTurtleRotationCorrectionCapability");
	default CapabilityTags.Add(n"SnowTurtle");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASnowTurtleBaby Turtle;

	bool bCompletedRotation;

	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Turtle = Cast<ASnowTurtleBaby>(Owner);
		bCompletedRotation = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Turtle.bIsInNest && !bCompletedRotation)
        	return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bCompletedRotation)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccelRot.SnapTo(Turtle.SkeletalMeshComponent.WorldRotation);
		// System::SetTimer(this, n"SetDeactivationBool", 2.f, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		RotationCorrection(DeltaTime);
		PrintToScreen("NewSkelMeshRotation");
	}

	void RotationCorrection(float DeltaTime)
	{
		const FRotator NewSkelMeshRotation = FRotator::MakeFromX(-Turtle.NestForwardVector);
		AccelRot.AccelerateTo(NewSkelMeshRotation, 1.f, DeltaTime);
		Turtle.SkeletalMeshComponent.SetWorldRotation(AccelRot.Value);
	}

	UFUNCTION()
	void SetDeactivationBool()
	{
		bCompletedRotation = true;
	}
}