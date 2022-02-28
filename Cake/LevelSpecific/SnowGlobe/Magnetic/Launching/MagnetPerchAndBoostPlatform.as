
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;

UCLASS(Abstract, HideCategories = "Rendering Debug Replication Input Actor LOD Cooking")
class AMagneticPerchAndBoostPlatform : AMagnetBasePad
{
	default MagneticCompCody.bCanBoost = true;
	default MagneticCompCody.bCanAttract = true;
	default MagneticCompMay.bCanAttract = true;
	default MagneticCompMay.bCanBoost = true;
}