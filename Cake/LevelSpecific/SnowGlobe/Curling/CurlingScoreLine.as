class ACurlingScoreLine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	FVector AxisRightVector;
	FVector CrossProductDirection;
	FVector ForwardVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForwardVector = ActorForwardVector;
		CrossProductDirection = ForwardVector.CrossProduct(FVector::UpVector);
		AxisRightVector = ActorRightVector;
	}
}