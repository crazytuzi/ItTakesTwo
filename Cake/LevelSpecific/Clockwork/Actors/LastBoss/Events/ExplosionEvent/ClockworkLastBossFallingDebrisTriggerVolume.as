import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossFallingDebris;
class AClockworkLastBossFallingDebrisTriggerVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;
	default Box.LineThickness = 10.f;

	UPROPERTY()
	AClockworkLastBossFallingDebris ConnectedDebris;

	UPROPERTY()
	EHazePlayer PlayerInControl;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"BoxOverlap");
		AHazePlayerCharacter PlayerControl = PlayerInControl == EHazePlayer::Cody ? Game::GetCody() : Game::GetMay();
		SetControlSide(PlayerControl);
	}

	UFUNCTION()
	void BoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		if (ConnectedDebris == nullptr)
			return;

		ConnectedDebris.NetStartMovingDebris();
	}
}