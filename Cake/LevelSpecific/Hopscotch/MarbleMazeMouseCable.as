class AMarbleMazeMouseCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeCableComponent CableComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CableComp.SetComponentTickEnabled(false);
	}

	UFUNCTION()
	void ResetCable()
	{
		CableComp.SetComponentTickEnabled(true);
		CableComp.TeleportCable(GetActorLocation());
		CableComp.ResetParticleVelocities();
		CableComp.ResetParticleForces();
	}
}