class ACurlingTargetPoint : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CurlingMeshComp;
	default CurlingMeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
}