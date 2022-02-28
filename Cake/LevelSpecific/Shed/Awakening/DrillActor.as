import Vino.Interactions.InteractionComponent;
import Peanuts.Position.TransformActor;

class ADrillActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Grip;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Drill;

	UPROPERTY()
	AHazeActor HangPosCody;

	UPROPERTY()
	AHazeActor HangPosMay;

	UPROPERTY()
	AActor JumpLocation;

	UPROPERTY()
	float RotateSpeed;

	UPROPERTY()
	float AdditionalHeight;

	bool bIsOn = true;


    UFUNCTION()
    void LaunchPlayers()
    {
		int index = 0;
		for (auto player :  Game::GetPlayers())
		{
			Landed(player);
		}
    }

	UFUNCTION()
	void SnapPlayerToDrill(AHazePlayerCharacter Player)
	{

		FVector TeleportLocation;

		if (Player.IsCody())
		{
			TeleportLocation = HangPosCody.ActorLocation;
		}
		else
		{
			TeleportLocation = HangPosMay.ActorLocation;
		}

		Player.TeleportActor(TeleportLocation, HangPosMay.ActorRotation);
		Player.SetCapabilityAttributeObject(n"InteractingWithDrill", this);
	}

	UFUNCTION()
	void Landed(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		Actor.SetCapabilityAttributeObject(n"InteractingWithDrill", this);
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsOn)
		{
			FRotator RotationDelta;
			RotationDelta.Roll = RotateSpeed * DeltaTime;
			Drill.AddLocalRotation(RotationDelta);
		}
	}
}