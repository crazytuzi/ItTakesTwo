

/*
 * This is a helper lib for all the standard functions for the activation point
 */
import Vino.ActivationPoint.ActivationPointStatics;


/*
 * This is an example and explanation of the activation point in the activation point system
 */
class UExampleActivationPoint : UHazeActivationPoint
{	
	/* This will make the points query data update with interval.
	 * This is very good to use if there is a lot of points of the same type
	 * since this will split up the amount in the the segment count.
	 * So EveryOtherFrame, the points will update there data 50/50 etc...
	*/
	default EvaluationInterval = EHazeActivationPointTickIntervalType::EveryOtherFrame;

	/* This is the distance where the first level of the points gui should show up.
	 * If the point dont have a widget attached to it, this does nothing.
	*/
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 3500.f);
	
	/* This is the distance where the second level of the points gui should show up.
	 * At this distance, this the point starts evaulating if it can be targeted nor not.
	*/
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 2500.f);
	
	/* This is the distance where the third level of the points gui should show up.
	 * At this distance, the point can be activated.
	*/
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 1000.f);
	
	/* This determains who can activate this point */
	default ValidationType = EHazeActivationPointActivatorType::Both;

	/* This determains what kind of point this is.
	 * Example; Magnets are 'Default', Swingpoints are 'Movement'.
	 * Only 1 point in each category can be a valid target.
	 * Only 1 point in total can be the current active point.
	*/
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Default;

	/* This param is used to calculate the distance in the query param */
	default BiggestDistanceType = EHazeActivationPointDistanceType::Visible;

	/* Activation points never tick by default. If you want that, you need to activate the tick */
	default PrimaryComponentTick.bStartWithTickEnabled = false;


	/* This function is called when the player is this point to be the current active on.
	 * OBS! Activating a point will always deactivate the current point (if there is one) first.
	 */
	UFUNCTION(BlueprintOverride)
	void OnPointActivatedBy(AHazePlayerCharacter Player)
	{
		// You can also subscribe to 'OnActivatedBy' delegate
	}

	/* This function is called when the player removes the current active point.
	 */
	UFUNCTION(BlueprintOverride)
	void OnPointDeactivatedBy(AHazePlayerCharacter Player)
	{
		// You can also subscribe to 'OnDeactivatedBy' delegate
	}

	/* This function is called when the player starts targeting this point. */
	UFUNCTION(BlueprintOverride)
	void OnPointTargetedBy(AHazePlayerCharacter Player)
	{
		
	}

	/* This function is called when the player no longer targets this point */
	UFUNCTION(BlueprintOverride)
	void OnPointTargetingLostBy(AHazePlayerCharacter Player)
	{

	}

	/* OPTIONAL TO OVERRIDE!
	 * If this function is implemented, you can change when the point is valid to target or not.
	*/
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		// This is a helper to test the line of sight to the activation point
		FFreeSightToActivationPointParams ExtraStuff;

		if(ActivationPointsStatics::HasFreeSightToActivationPoint(Player, Query, ExtraStuff))
		 	return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::InvalidAndHidden;
	}

	/* OPTIONAL TO OVERRIDE!
	 * If this function is implemented, you can change how valid this point is to be the best target.
	 * 1.0 means that this point is as good as it gets down to 0.0 where you don't want this point unless there is nothing else.
	 * @CompareDistanceAlpha: This querys distance to the player in releation to the current point that is furthest away of all the queries this frame
	*/
	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		// The standard function for getting a nice validation score. Usually you want to use this function.
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}



	/* (Usually you never override this.) OPTIONAL TO OVERRIDE!
	 * With this function, you can change how the attach widget should be shown.
	*/
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	{	
		
		return EHazeActivationPointStatusType::Valid;
	}

	/* (Usually you never override this.) OPTIONAL TO OVERRIDE!
	 * With this function, you can change where the activation points transform is for a specific player
	*/
	UFUNCTION(BlueprintOverride)
	FTransform GetTransformFor(AHazePlayerCharacter Player) const
	{	
		return FTransform::Identity;
	}

}

/*
 * This is an example and explanation of how you use the activation point widget
 */
UCLASS(abstract)
class UExampleActivationWidget : UHazeActivationPointWidget
{
	/* This function is called when the widget is attached to a new player or point
	*/
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UHazeActivationPoint MyOwner = GetOwningPoint();
	}

	/* This function is called every frame the widget has been querried
	*/
	UFUNCTION(BlueprintOverride)
	void InitializeForQuery(FHazeQueriedActivationPoint Query, EHazeActivationPointWidgetStatusType WantedVisibility)
	{
		
	}

	/* OPTIONAL TO OVERRIDE!
	 * If you dont override this, the widget will have the same status as the 'SetupWidgetVisibility' function returned
	*/
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType GetRenderStatus()const
	{
		return EHazeActivationPointStatusType::Valid;
	}
}


/*
 * This is an example and explanation of how you use the activation point system
 * You should use player capabilities for activating and deactivating the points
 */
class UHandleExampleActivationPointCapability : UHazeCapability
{
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		/* You can call query and get all the results. 
		 * Use this function to update the widget
		*/
		TArray<FHazeQueriedActivationPoint> Querries;
		Player.QueryActivationPoints(UExampleActivationPoint::StaticClass(), Querries);

		/* This function will update the widget. If this is not called, no widgets will show up */
		Player.UpdateActivationPointAndWidgets(UExampleActivationPoint::StaticClass());

		/* The query function will prepare the best target (If there is any)
		 * This is how you read the target point.
		*/
		UExampleActivationPoint CurrentTargetPoint = Cast<UExampleActivationPoint>(Player.GetTargetPoint(UExampleActivationPoint::StaticClass()));
		
		/* You can also read the current target as a query
		*/
		FHazeQueriedActivationPoint Query;
		bool bHasTarget = Player.GetTargetPoint(UExampleActivationPoint::StaticClass(), Query);

		/* When you have found a target point, you can activate it. */
		Player.ActivatePoint(CurrentTargetPoint, Instigator = this);

		/* The activated point can be retreived with this function */
		UHazeActivationPoint ActivatedPoint = Player.GetActivePoint();

		/* The widget for the current active point is never shown by default 
		 * If you want to show it, you can query the active point
		*/
		FHazeQueriedActivationPoint ActiveQuery;
		if(Player.GetActivePoint(UExampleActivationPoint::StaticClass(), ActiveQuery))
		{
			/* This will update the widget on the current active point */
			Player.UpdateActivationPointWidget(ActiveQuery);
		}

		/* This is how you check if you are still the current instigator of the activation */
		bool bIAmStillTheInstigator = Player.CurrentActivationInstigatorIs(this);

		/* When you don't want to have the point as active, you call this function */
		Player.DeactivateCurrentPoint();
	}
}
