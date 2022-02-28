class ASurveillanceSatelliteDishFocusPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(15.f);

	UPROPERTY()
	UAkAudioEvent StartEvent;

	UPROPERTY()
	UAkAudioEvent StopEvent;

	UPROPERTY()
	UFoghornBarkDataAsset BarkAsset;

	UPROPERTY()
	FName MayReplyEvent;

	UPROPERTY()
	FName CodyReplyEvent;

	bool bFullyListened = false;

	void SetFocusPointFullyListened()
	{
		bFullyListened = true;
	}
}