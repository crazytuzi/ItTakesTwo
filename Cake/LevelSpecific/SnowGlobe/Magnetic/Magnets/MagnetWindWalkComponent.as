import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagnetWindWalkComponent : UMagnetGenericComponent
{
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{
		// Invalidate magnet if player is jumping whilst MPAing
		UMagneticPlayerAttractionComponent MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(Player.OtherPlayer);
		if(MagneticPlayerAttraction != nullptr)
		{
			if(MagneticPlayerAttraction.IsPlayerAttractionActive() && !Player.MovementComponent.IsGrounded())
				return EHazeActivationPointStatusType::Invalid;
		}

		return Super::SetupActivationStatus(Player, Query);
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const override
	{
		return Super::SetupWidgetVisibility(Player, Query);
	}
}