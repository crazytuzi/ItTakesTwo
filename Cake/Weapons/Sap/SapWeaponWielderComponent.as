import Cake.Weapons.Sap.SapWeapon;
import Cake.Weapons.Sap.SapWeaponSettings;
import Cake.Weapons.Sap.SapWeaponAimStatics;
import Cake.Weapons.Sap.SapWeaponNames;
import Cake.Weapons.Sap.SapWeaponContainer;
import Cake.Weapons.Sap.SapWeaponCrosshairWidget;
import Cake.Weapons.Sap.SapWeaponFullscreenCrosshairWidget;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Peanuts.Aiming.AutoAimStatics;

class USapWeaponWielderComponent : UActorComponent
{
	UPROPERTY()
	ASapWeapon Weapon;

	// Used to keep track of how many weapons have been spawned, to make unique identifiers
	int WeaponSpawnCount = 0;

	bool bFullscreenAim = false;

	UPROPERTY(BlueprintReadOnly)
	bool bIsAiming = false;

	FSapAttachTarget AimTarget;
	FVector AimSurfaceNormal;

	// Pressure mechanic, the less pressure, the slower the fire speed
	float Pressure = 1.f;
	float PressurePauseTimer = 0.f;

	bool bShouldAimPredict = false;
	bool bShouldInheritGroundVelocity = true;

	UPROPERTY(Category = "Pressure")
	UCurveFloat FloatCurve;

	UPROPERTY(Category = "Rumble")
	UForceFeedbackEffect ShootRumbleEffect;

	UPROPERTY(Category = "Animation")
	FVector2D AimAngles;

	UPROPERTY(Category = "Animation")
	bool bAnimIsShooting = false;

	UPROPERTY(Category = "Animation")
	bool bAnimShotThisFrame = false;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset Locomotion;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset AimLocomotion;

	UPROPERTY(Category = "Animation")
	bool bAimingWasBlocked = false;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset AimCameraSettings;

	UPROPERTY(Category = "Widget")
	TSubclassOf<USapWeaponCrosshairWidget> CrosshairWidgetClass;

	UPROPERTY(Category = "Widget")
	TSubclassOf<USapWeaponFullscreenCrosshairWidget> FullscreenCrosshairWidgetClass;

	// Used to keep track how many times Cody hits a sticky surface, for VO stuff
	UPROPERTY(Category = "VO")
	int NumStickyHits = 0;

	void AddPressure(float Amount)
	{
		Pressure = FMath::Min(Pressure + Amount, Sap::Pressure::Max);
	}

	void RemovePressure(float Amount)
	{
		Pressure = FMath::Max(Pressure - Amount, 0.f);
		PressurePauseTimer = Sap::Pressure::RegenPause;
	}

	float GetCurrentFireRate()
	{
		float FireRateMultiplier = FloatCurve.GetFloatValue(Pressure / Sap::Pressure::Max);
		return Sap::Shooting::FireRate * FireRateMultiplier;
	}
}