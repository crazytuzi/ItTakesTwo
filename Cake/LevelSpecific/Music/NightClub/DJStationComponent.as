import Peanuts.Animation.Features.Music.LocomotionFeatureMusicDJ;
import Cake.LevelSpecific.Music.NightClub.DJStandType;

import EDJStandType GetDJStandTypeFromActor(AHazeActor) from "Cake.LevelSpecific.Music.NightClub.DJVinylPlayer";

UCLASS(hidecategories = "ComponentReplication Activation Cooking Tags AssetUserData Collision Variable ComponentTick")
class UDJStationComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(NotEditable)
	AHazeActor VinylPlayer;

	UPROPERTY(Category = Animation)
	protected ULocomotionFeatureMusicDJ Cody_DJStateMachine;

	UPROPERTY(Category = Animation)
	protected ULocomotionFeatureMusicDJ May_DJStateMachine;

	ULocomotionFeatureMusicDJ GetAnimFeature(AHazePlayerCharacter Player) const
	{
		return Player.IsMay() ? May_DJStateMachine : Cody_DJStateMachine;
	}

	UFUNCTION(BlueprintPure)
	EDJStandType GetDJStandType() const
	{
		return GetDJStandTypeFromActor(VinylPlayer);
	}

	UPROPERTY(Category = "Animation|LightTable")
	UAnimSequence May_LightTable;

	UPROPERTY(Category = "Animation|LightTable")
	UAnimSequence Cody_LightTable;

	UPROPERTY(Category = "Animation|SmokeMachine")
	UAnimSequence May_SmokeMachine;

	UPROPERTY(Category = "Animation|SmokeMachine")
	UAnimSequence Cody_SmokeMachine;

	UPROPERTY(Category = "Animation|Pendelum")
	TArray<UAnimSequence> May_Pendelum;

	UPROPERTY(Category = "Animation|Pendelum")
	TArray<UAnimSequence> Cody_Pendelum;

	UPROPERTY(Category = "Animation|SpinStick")
	UAnimSequence May_SpinStick;

	UPROPERTY(Category = "Animation|SpinStick")
	UAnimSequence Cody_SpinStick;

	UAnimSequence GetRandomPendulumAnim(AHazePlayerCharacter InPlayer) const
	{
		if(InPlayer.IsMay())
			return GetRandomPendulumAnimSequence(May_Pendelum);

		return GetRandomPendulumAnimSequence(Cody_Pendelum);
	}

	private UAnimSequence GetRandomPendulumAnimSequence(TArray<UAnimSequence> Anims) const
	{
		if(Anims.Num() == 0)
			return nullptr;

		if(Anims.Num() == 1)
			return Anims[0];

		int RandomIndex = FMath::RandRange(0, Anims.Num() - 1);
		return Anims[RandomIndex];
	}
}
