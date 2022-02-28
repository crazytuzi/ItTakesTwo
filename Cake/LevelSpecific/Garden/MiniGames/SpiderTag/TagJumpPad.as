import Vino.Movement.Helpers.BurstForceStatics;
class ATagJumpPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	float VerticalVelocity = 2500.f;

	UPROPERTY()
	float HorizontalVelocity = 300.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			FVector ForwardForce = Player.ActorForwardVector * HorizontalVelocity;
			FVector UpwardForce(0.f, 0.f, VerticalVelocity);
			FVector BurstForce = ForwardForce + UpwardForce;
			Player.AddBurstForce(BurstForce, Player.ActorRotation);
		}
    }

}