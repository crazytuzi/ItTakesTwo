import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomActivationPoints;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomStatics;
class ALightRoomSpotlightLocationActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Capsule;
	default Capsule.bHiddenInGame = true;

	bool bIsProvidingLight = true;

	UPROPERTY()
	ELightRoomSpotlight SpotlightType;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capsule.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		Capsule.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if(!HasControl())
			return;
		
		if (!bIsProvidingLight)
			return;

		ALightRoomActivationPoints ActivationPoint = Cast<ALightRoomActivationPoints>(OtherActor);
		if (ActivationPoint != nullptr)
		{
			NetOnBeginOverlap(ActivationPoint);
		}
	}

	UFUNCTION(NetFunction)
	private void NetOnBeginOverlap(ALightRoomActivationPoints ActivationPoint)
	{
		ActivationPoint.OverlappedByLight(SpotlightType, this);
	}

	UFUNCTION()
	void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if(!HasControl())
			return;

		ALightRoomActivationPoints ActivationPoint = Cast<ALightRoomActivationPoints>(OtherActor);
		if (ActivationPoint != nullptr)
		{
			NetOnEndOverlap(ActivationPoint);
		}
	}

	UFUNCTION(NetFunction)
	private void NetOnEndOverlap(ALightRoomActivationPoints ActivationPoint)
	{
		ActivationPoint.EndOverlapByLight(SpotlightType, this);
	}

	bool IsProvidingLightToPlayer(AHazePlayerCharacter Player)
	{
		if (!bIsProvidingLight)
			return false;
		else
			return Capsule.IsOverlappingActor(Player);
	}
}