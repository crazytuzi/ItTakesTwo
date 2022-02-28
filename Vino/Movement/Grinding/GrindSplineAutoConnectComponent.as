
struct FSplineConnectionIDs
{
	int NormalID = 0;
	int FlatID = 0;
}

class UGrindSplineAutoConnectComponent : UBoxComponent
{
	UPROPERTY()
	UHazeSplineComponentBase NormalSpline;

	UPROPERTY()
	UHazeSplineComponentBase FlatSpline;
	
	UPROPERTY(BlueprintReadOnly)
	bool bEnabled = true;

	UPROPERTY(BlueprintReadOnly)
	bool bConnectForward = true;

	UPROPERTY(BlueprintReadOnly)
	bool bConnectBackward = true;

	UPROPERTY(BlueprintReadOnly)
	bool bEnterFacingForward = true;

	UPROPERTY()
	float EntryDistance = 0.f;

	UPROPERTY()
	float FlatEntryDistance = 0.f;

	TMap<UGrindSplineAutoConnectComponent, FSplineConnectionIDs> EstablishedConnections;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bEnabled)
			return;

		TArray<UPrimitiveComponent> Overlaps;
		GetOverlappingComponents(Overlaps);

		for (auto OverlapComp : Overlaps)
		{
			auto OtherComp = Cast<UGrindSplineAutoConnectComponent>(OverlapComp);
			if (OtherComp != nullptr)
			{
				EstablishConnection(OtherComp);
				OtherComp.EstablishConnection(this);
			}
		}

        OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
        OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	void SetupSplines(UHazeSplineComponentBase Spline, UHazeSplineComponentBase FlattenedSpline)
	{
		NormalSpline = Spline;
		FlatSpline = FlattenedSpline;
	}

	void EstablishConnection(UGrindSplineAutoConnectComponent OtherComp)
	{
		if (!devEnsure(SplinesAreValid(), "GrindSplineAutoConnection not correctly setup"))
			return;

		if (EstablishedConnections.Contains(OtherComp))
			return;

		float ExitDistance = OtherComp.EntryDistance;
		if (EntryDistance == ExitDistance && NormalSpline == OtherComp.NormalSpline)
		{
			devEnsure(false, "Spline automatic connect boxes can only connect to the same spline if they have a 'force entry distance' set.");
			return;
		}

		FSplineConnectionIDs PotentialConnection;
		ConnectToSpline(NormalSpline, OtherComp.NormalSpline, EntryDistance, OtherComp.EntryDistance, OtherComp, PotentialConnection.NormalID);
		ConnectToSpline(FlatSpline, OtherComp.FlatSpline, FlatEntryDistance, OtherComp.FlatEntryDistance, OtherComp, PotentialConnection.FlatID);
		EstablishedConnections.Add(OtherComp, PotentialConnection);
	}

	void ConnectToSpline(UHazeSplineComponentBase LocalSpline, UHazeSplineComponentBase OtherSpline, float Distance, float ExitDistance, UGrindSplineAutoConnectComponent OtherComp, int& OutID)
	{
		FHazeSplineConnection Connection;

		Connection.DistanceOnEntrySpline = Distance;
		Connection.DistanceOnExitSpline = ExitDistance;

		Connection.bCanEnterGoingBackward = bConnectBackward;
		Connection.bCanEnterGoingForward = bConnectForward;
		Connection.ExitSpline = OtherSpline;
		Connection.bExitForwardOnSpline = OtherComp.bEnterFacingForward;

		OutID = LocalSpline.AddSplineConnection(Connection);
	}

	void DestroyConnection(UGrindSplineAutoConnectComponent OtherComp)
	{
		FSplineConnectionIDs IDs;
		if (EstablishedConnections.Find(OtherComp, IDs))
		{
			EstablishedConnections.Remove(OtherComp);
			NormalSpline.RemoveSplineConnection(IDs.NormalID);
			FlatSpline.RemoveSplineConnection(IDs.FlatID);
		}
	}

    UFUNCTION()
    void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		auto OtherConn = Cast<UGrindSplineAutoConnectComponent>(OtherComponent);
		if (OtherConn != nullptr)
			EstablishConnection(OtherConn);
    }

    UFUNCTION()
    void OnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto OtherConn = Cast<UGrindSplineAutoConnectComponent>(OtherComponent);
		if (OtherConn != nullptr)
			DestroyConnection(OtherConn);
    }

	bool SplinesAreValid() const
	{
		return NormalSpline != nullptr && FlatSpline != nullptr;
	}
}
