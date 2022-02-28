import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagnetIceSkatingMagnetComponent : UMagneticComponent
{
	UPROPERTY()
	float Force = 10000.f;

	UPROPERTY()
	bool bUseConstantForce;
}