import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.UserGrindComponent;

class UGrindingTransferActivationPoint : UHazeActivationPoint
{
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;

	default InitializeDistance(EHazeActivationPointDistanceType::Visible, GrindSettings::Transfer.WidgetDistance);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, GrindSettings::Transfer.WidgetDistance);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, GrindSettings::Transfer.WidgetDistance);

	default WidgetClass = Asset("/Game/Blueprints/LevelMechanics/WBP_GrindTransferWidget.WBP_GrindTransferWidget_C");
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		return 1.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{
		UUserGrindComponent UserGrindComp = UUserGrindComponent::Get(Player);

		if (!UserGrindComp.HasActiveGrindSpline())		
			return EHazeActivationPointStatusType::Invalid;
		
		// Transfer eval will attach the activation point to the target grind rail
		if (Query.Point.AttachParent != nullptr && Query.Point.AttachParent.Owner != nullptr)
		{
			AGrindspline QueryGrindSpline = Cast<AGrindspline>(Query.Point.AttachParent.Owner);
			if (QueryGrindSpline != nullptr)
			{
				if (QueryGrindSpline.bTransferIgnoreCollisionTest)
					return EHazeActivationPointStatusType::Valid;
			}
		}

		FFreeSightToActivationPointParams Params;
		if(!ActivationPointsStatics::CanPlayerReachActivationPoint(Player, Query, Params))
			return EHazeActivationPointStatusType::Invalid;
	
		return EHazeActivationPointStatusType::Valid;
	}
}
