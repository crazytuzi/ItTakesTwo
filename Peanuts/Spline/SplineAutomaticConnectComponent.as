
class USplineAutomaticConnectComponent : UBoxComponent
{
	UPROPERTY(BlueprintReadOnly)
	bool bEnabled = true;

	UPROPERTY(BlueprintReadOnly)
	bool bConnectForward = true;

	UPROPERTY(BlueprintReadOnly)
	bool bConnectBackward = true;

	UPROPERTY(BlueprintReadOnly)
	bool bEnterFacingForward = true;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bOverrideAnchorDistance = false;

	UPROPERTY(Meta = (EditCondition = "bOverrideAnchorDistance"))
	float AnchorDistanceOverride = 0.f;

	TMap<USplineAutomaticConnectComponent, int> EstablishedConnections;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bEnabled)
			return;

		TArray<UPrimitiveComponent> Overlaps;
		GetOverlappingComponents(Overlaps);

		for (auto OverlapComp : Overlaps)
		{
			auto OtherComp = Cast<USplineAutomaticConnectComponent>(OverlapComp);
			if (OtherComp != nullptr)
			{
				CreateConnection(OtherComp);
				OtherComp.CreateConnection(this);
			}
		}

        OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
        OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UHazeSplineComponentBase GetSpline() property
	{
		return UHazeSplineComponentBase::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (!bOverrideAnchorDistance && Spline != nullptr)
		{
			FVector ClosestPos;
			float Distance = 0.f;
			Spline.FindDistanceAlongSplineAtWorldLocation(WorldLocation, ClosestPos, Distance);

			AnchorDistanceOverride = Distance;
		}
	}

	void CreateConnection(USplineAutomaticConnectComponent OtherComp)
	{
		if (EstablishedConnections.Contains(OtherComp))
			return;

		FHazeSplineConnection Connection;

		FVector ClosestPos;
		float EntryDistance = 0.f;
		Spline.FindDistanceAlongSplineAtWorldLocation(WorldLocation, ClosestPos, EntryDistance);

		if (bOverrideAnchorDistance)
			EntryDistance = AnchorDistanceOverride;

		FVector ExitWorldPos = WorldLocation;
		if (Spline == OtherComp.Spline)
			ExitWorldPos = OtherComp.WorldLocation;

		float ExitDistance = 0.f;
		OtherComp.Spline.FindDistanceAlongSplineAtWorldLocation(ExitWorldPos, ClosestPos, ExitDistance);

		if (OtherComp.bOverrideAnchorDistance)
			ExitDistance = OtherComp.AnchorDistanceOverride;

		if (EntryDistance == ExitDistance && Spline == OtherComp.Spline)
		{
			devEnsure(false, "Spline automatic connect boxes can only connect to the same spline if they have a 'force entry distance' set.");
			return;
		}

		Connection.DistanceOnEntrySpline = EntryDistance;
		Connection.DistanceOnExitSpline = ExitDistance;

		Connection.bCanEnterGoingBackward = bConnectBackward;
		Connection.bCanEnterGoingForward = bConnectForward;
		Connection.ExitSpline = OtherComp.Spline;
		Connection.bExitForwardOnSpline = OtherComp.bEnterFacingForward;

		int ConnectionId = Spline.AddSplineConnection(Connection);
		EstablishedConnections.Add(OtherComp, ConnectionId);
	}

	void DestroyConnection(USplineAutomaticConnectComponent OtherComp)
	{
		int ConnectionId = -1;
		if (EstablishedConnections.Find(OtherComp, ConnectionId))
		{
			EstablishedConnections.Remove(OtherComp);
			Spline.RemoveSplineConnection(ConnectionId);
		}
	}

    UFUNCTION()
    void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		auto OtherConn = Cast<USplineAutomaticConnectComponent>(OtherComponent);
		if (OtherConn != nullptr)
			CreateConnection(OtherConn);
    }

    UFUNCTION()
    void OnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto OtherConn = Cast<USplineAutomaticConnectComponent>(OtherComponent);
		if (OtherConn != nullptr)
			DestroyConnection(OtherConn);
    }
};