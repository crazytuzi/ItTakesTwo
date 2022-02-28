import Vino.Tilt.TiltComponent;
class ATiltingCymbal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnPlayerLandedEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnPlayerLeftEvent;

	int32 PlayerImpactCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{			
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"AudioOnHit");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"AudioOnLeave");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}	

	UFUNCTION()
	void AudioOnHit(AHazePlayerCharacter Player, const FHitResult& HitResult)
	{
		PlayerImpactCount ++;
		HazeAkComp.HazePostEvent(OnPlayerLandedEvent);
	}

	UFUNCTION()
	void AudioOnLeave(AHazePlayerCharacter Player)
	{
		PlayerImpactCount --;

		if(PlayerImpactCount == 0)
		{
			HazeAkComp.HazePostEvent(OnPlayerLeftEvent);
		}
	}
}