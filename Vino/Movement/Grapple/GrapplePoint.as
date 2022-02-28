import Vino.ActivationPoint.ActivationPointStatics;

class AGrapplePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrapplePointComponent ActivationPoint;
}

class UGrapplePointComponent : UHazeActivationPoint
{
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;

	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 5000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 3500.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 2250.f);	

	default WidgetClass = Asset("/Game/Blueprints/Movement/Grapple/WBP_GrappleActivationWidget.WBP_GrappleActivationWidget_C");

	UPROPERTY(Category = Settings)
	bool bEnabled = true;

	UPROPERTY(Category = Settings)
	TPerPlayer<bool> EnabledForPlayer;
	default EnabledForPlayer[0] = true;
	default EnabledForPlayer[1] = true;

	UPROPERTY(Category = Settings)
	float InvalidMinDistance = 300.f;

	UPROPERTY(Category = Settings, meta = (MakeEditWidget))
	FVector TargetLocationOffset;

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		// Should score to 1.f total, and take camera into account a lot more than it does with the function below
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if (!bEnabled)
			return EHazeActivationPointStatusType::Invalid;

		if (!EnabledForPlayer[Player])
			return EHazeActivationPointStatusType::Invalid;

		FFreeSightToActivationPointParams Params;
		if(!ActivationPointsStatics::CanPlayerReachActivationPoint_Expensive(Player, Query, Params))
			return EHazeActivationPointStatusType::Invalid;

		if ((Player.ActorLocation - WorldLocation).Size() < InvalidMinDistance)
			return EHazeActivationPointStatusType::Invalid;


		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION()
	void EnableGrapplePoint()
	{
		bEnabled = true;
	}

	UFUNCTION()
	void DisableGrapplePoint()
	{
		bEnabled = false;
	}

	UFUNCTION()
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		EnabledForPlayer[Player] = true;
	}

	UFUNCTION()
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		EnabledForPlayer[Player] = false;
	}
}
