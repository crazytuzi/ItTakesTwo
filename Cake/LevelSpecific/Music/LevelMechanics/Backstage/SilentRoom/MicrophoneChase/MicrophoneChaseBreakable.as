import Cake.Environment.Breakable;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonster;

class AMicrophoneChaseBreakable : ABreakableActor
{
	UPROPERTY(DefaultComponent, Attach = BreakableComponent)
	UBoxComponent BoxCollision;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
	}

	UFUNCTION()
	void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AMicrophoneMonster Monster = Cast<AMicrophoneMonster>(OtherActor);
		if (Monster == nullptr)
			return;

		Game::GetCody().PlayCameraShake(CamShake);

		FBreakableHitData BreakData;
		// BreakData.DirectionalForce = Hit.Normal * FMath::RandRange(150.f, 250.f);
		// BreakData.HitLocation = GetActorLocation();
		// BreakData.ScatterForce = FMath::RandRange(8.f, 20.f);
		BreakableComponent.Break(BreakData);
	}
}