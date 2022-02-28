import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
class AMarbleSpinner : AActor
{

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SpinnerMesh;

	bool CanSpin = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnTriggeredBeginOverlap");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"OnTriggeredEndOverlap");
	}

	UFUNCTION()
    void OnTriggeredBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AMarbleBall Marble = Cast<AMarbleBall>(OtherActor);

		if (CanSpin && Marble != nullptr)
		{
			float Speed = Marble.PhysicalVelocity.Size();
			CanSpin = false;
			TriggerSpinEffects(Speed);
		}
    }

    UFUNCTION()
    void OnTriggeredEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		MarbleLeftSpinner();
    }

	UFUNCTION(BlueprintEvent)
	void TriggerSpinEffects(float Speed)
	{

	}

	UFUNCTION(BlueprintEvent)
	void MarbleLeftSpinner()
	{
		CanSpin = true;
	}
}