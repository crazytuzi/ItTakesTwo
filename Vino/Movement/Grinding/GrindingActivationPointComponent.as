import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;

class UGrindingActivationComponent : UHazeActivationPoint
{
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;

	default InitializeDistance(EHazeActivationPointDistanceType::Visible, GrindSettings::Grapple.MaxRange + 2000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, GrindSettings::Grapple.MaxRange + 1000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, GrindSettings::Grapple.MaxRange);

	default WidgetClass = Asset("/Game/Blueprints/LevelMechanics/WBP_GrindActivationWidget.WBP_GrindActivationWidget_C");
	default BiggestDistanceType = EHazeActivationPointDistanceType::Visible;

	bool bHasPotentialTarget = false;

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{
		UUserGrindComponent UserGrindComp = UUserGrindComponent::Get(Player);

		if (!bHasPotentialTarget)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if (UserGrindComp.HasActiveGrindSpline())
			return EHazeActivationPointStatusType::Invalid;

		if (AttachParent == nullptr)
			return EHazeActivationPointStatusType::Invalid;

		if (Player.IsAnyCapabilityActive(LedgeGrabTags::HangMove))
			return EHazeActivationPointStatusType::Invalid;

		EHazeActivationAsyncStatusType TraceType = CanPlayerReachActivationPoint(Player, Query);
		
		if(TraceType == EHazeActivationAsyncStatusType::NoData)
			return EHazeActivationPointStatusType::Invalid;

		if(TraceType == EHazeActivationAsyncStatusType::TraceFoundCollision)
			return EHazeActivationPointStatusType::Invalid;

		return EHazeActivationPointStatusType::Valid;
	}

	EHazeActivationAsyncStatusType CanPlayerReachActivationPoint(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& QueryPoint) const
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);

		FHazeTraceParams Settings;
		Settings.InitWithMovementComponent(MoveComp);
		FVector2D CurrentCollisionSettings(Settings.TraceShape.GetCapsuleRadius(), Settings.TraceShape.GetCapsuleHalfHeight());
		Settings.TraceShape.SetSphere(CurrentCollisionSettings.X);
	
		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();
		Settings.IgnoreActor(PointOwner);
		Settings.IgnoreActor(AttachParent.Owner);
		
		AActor PointAttachParent = PointOwner.GetAttachParentActor();
		if (PointAttachParent != nullptr)
			Settings.IgnoreActor(PointAttachParent);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		// Setup trace target
		Settings.From = Player.ActorLocation + (Player.CapsuleComponent.UpVector * CurrentCollisionSettings.Y * 1.5f);

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();
		Settings.To += MoveComp.WorldUp * Player.GetCollisionSize().Y;

		FHitResult HitResult;
		return QueryPoint.AsyncTrace(Player, Settings, HitResult);
	}
}
