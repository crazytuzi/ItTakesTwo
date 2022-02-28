class ASnowTurtleBlockingCollider : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Block);

}