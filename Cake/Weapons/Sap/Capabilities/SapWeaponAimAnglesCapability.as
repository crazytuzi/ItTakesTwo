import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Camera.Components.CameraUserComponent;
import Rice.Math.MathStatics;

class USapWeaponAimAnglesCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);
//	default CapabilityTags.Add(SapWeaponTags::Aim);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 75;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;

	USapWeaponCrosshairWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Get what our velocity will be when shooting
		FVector Velocity = CalculateSapExitVelocity(Wielder.Weapon.MuzzleLocation, Wielder.AimTarget);

		// ... then aim in that direction!
		FVector AimDirection = Velocity.GetSafeNormal();
		AimDirection.Normalize();

		// Calculate pitch
		float Pitch = AimDirection.DotProduct(Player.Mesh.UpVector);
		Pitch = FMath::Asin(Pitch) * RAD_TO_DEG;

		// Calculate yaw
		FVector FlatAimDirection = AimDirection.ConstrainToPlane(Player.Mesh.UpVector);
		FlatAimDirection.Normalize();

		float Yaw = Player.Mesh.ForwardVector.CrossProduct(FlatAimDirection).DotProduct(Player.Mesh.UpVector);
		Yaw = GetAngleBetweenVectorsAroundAxis(Player.Mesh.ForwardVector, AimDirection, Player.Mesh.UpVector);

		Wielder.AimAngles.Y = FMath::FInterpTo(Wielder.AimAngles.Y, Pitch, DeltaTime, 10.f);
		Wielder.AimAngles.X = FMath::FInterpTo(Wielder.AimAngles.X, Yaw, DeltaTime, 10.f);
	}
}