import Vino.Pickups.PickupActor;

class AAudioFeedbackMicrophone : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = PickupMesh)
	USphereComponent SphereComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
}