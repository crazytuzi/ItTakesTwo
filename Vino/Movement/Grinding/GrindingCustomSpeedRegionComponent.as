import Vino.Movement.Grinding.GrindingReasons;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.GrindingBaseRegionComponent;
import Vino.Movement.Grinding.GrindSettings;

class UGrindingCustomSpeedRegionComponent : UGrindingBaseRegionComponent
{
	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Purple;
	}

	UPROPERTY(Category = "GrindSpeed")
	FGrindBasicSpeedSettings CustomSpeed;
}

