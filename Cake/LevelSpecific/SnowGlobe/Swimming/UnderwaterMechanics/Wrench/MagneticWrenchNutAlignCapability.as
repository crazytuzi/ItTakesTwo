import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.MagneticWrenchActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchSettings;

class UMagneticWrenchNutAlignCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Wrench");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	AMagneticWrenchActor Wrench;
	UHazeMovementComponent MoveComp;

	AWrenchNutActor Nut;
	FMagneticWrenchSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Wrench = Cast<AMagneticWrenchActor>(Owner);
		MoveComp = Wrench.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wrench.ActiveNut == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (Wrench.ActiveNut.bIsFullyScrewed)
	        return EHazeNetworkActivation::DontActivate;

	    FVector ToNut = Wrench.ActorLocation - Wrench.ActiveNut.AttachSocket.WorldLocation;
	    ToNut.Normalize();

	    float Angle = Math::DotToDegrees(ToNut.DotProduct(Wrench.ActiveNut.AttachSocket.UpVector));
	    if (Angle > Settings.AlignMaxAngle)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wrench.ActiveNut == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (Wrench.ActiveNut.bIsFullyScrewed)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    FVector ToNut = Wrench.ActorLocation - Wrench.ActiveNut.AttachSocket.WorldLocation;
	    ToNut.Normalize();

	    float Angle = Math::DotToDegrees(ToNut.DotProduct(Wrench.ActiveNut.AttachSocket.UpVector));
	    if (Angle > Settings.AlignMaxAngle)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Nut = Wrench.ActiveNut;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Nut = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Rotate the wrench so that it faces the nut
		FVector NutUp = Nut.AttachSocket.UpVector;
		NutUp.Normalize();

		FVector WrenchUp = Wrench.ActorUpVector;
		if (WrenchUp.DotProduct(NutUp) < 0.f)
			WrenchUp = -WrenchUp;

		FVector Axis = WrenchUp.CrossProduct(NutUp);
		Axis.Normalize();

		float Angle = Math::DotToRadians(NutUp.DotProduct(WrenchUp));

		float DistanceToNut = Nut.AttachSocket.WorldLocation.Distance(Wrench.ActorLocation);
		float ForcePercent = 1.f - Math::Saturate(DistanceToNut / Settings.AlignMaxDistance);

		Wrench.AngularVelocity += Axis * Angle * ForcePercent * Settings.AlignAngularForce * DeltaTime;

		// Apply a force so that it moves towards the center of the nut
		FVector NutTarget = Nut.AttachSocket.WorldLocation + Nut.AttachSocket.UpVector * 100.f;
		FVector ToNut = NutTarget - Wrench.ActorLocation;
		Wrench.LinearVelocity += ToNut.GetSafeNormal() * ForcePercent * Settings.AlignLinearForce * DeltaTime;
		Wrench.LinearVelocity -= Wrench.LinearVelocity * Settings.AlignLinearDrag * ForcePercent * DeltaTime;

	}
}
