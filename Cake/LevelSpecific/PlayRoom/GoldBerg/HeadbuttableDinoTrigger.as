import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;


class UHeadButtableTriggeromponent: UBoxComponent
{
	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Bind to the component's overlap events. This can of course
        // be one from outside the component as well, but we're doing it
        // in begin play now. The functions we bind must be UFUNCTION()s
        OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
    }

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
        if (Cast<AHeadButtingDino>(OtherActor) != nullptr)
		{
			OtherActor.AttachToActor(Owner, n"", EAttachmentRule::KeepWorld);


		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (Cast<AHeadButtingDino>(OtherActor) != nullptr)
		{
        	OtherActor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}
    }
}