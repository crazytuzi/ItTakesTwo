class AMusicTunnelSpaceFloatManager : AHazeActor
{
	UPROPERTY()
	float MayDistanceAlongSpline;

	UPROPERTY()
	float CodyDistanceAlongSpline;

	UPROPERTY()
	bool MayIsFurtherAlongSpline;

	UPROPERTY()
	bool PlayersAreTogether;

	UPROPERTY()
	UNiagaraSystem SpaceTrailFX;

	UPROPERTY()
	AStaticMeshActor BlackHolePOI;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MayIsFurtherAlongSpline = MayDistanceAlongSpline > CodyDistanceAlongSpline;
			
		float DistanceBetweenPlayers = MayDistanceAlongSpline - CodyDistanceAlongSpline;
		DistanceBetweenPlayers = FMath::Abs(DistanceBetweenPlayers);

		PlayersAreTogether = DistanceBetweenPlayers < 200.f;
	}
}