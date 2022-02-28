import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;

void AddCarToPlayer(AHazePlayerCharacter Player, APullbackCar Car, bool bIsDriver)
{
	auto CarComp = UPullbackCarWindupCharacterAnimComponent::GetOrCreate(Player);
	CarComp.PullbackCar = Car;
	if(bIsDriver)
	{
		CarComp.bPlayerDrivingCar = true;
	}
	else
	{
		CarComp.bPlayerPullingCar = true;
	}
}

void RemoveCarFromPlayer(AHazePlayerCharacter Player, bool bIsDriver)
{
	auto CarComp = UPullbackCarWindupCharacterAnimComponent::Get(Player);
	if(CarComp != nullptr)
	{
		CarComp.PullbackCar = nullptr;
		if(bIsDriver)
		{
			CarComp.bPlayerDrivingCar = false;
		}
		else
		{
			CarComp.bPlayerPullingCar = false;
		}
	}
}

class UPullbackCarWindupCharacterAnimComponent : UActorComponent
{
	APullbackCar PullbackCar;

	UPROPERTY()
	float PullVelocity = 0.f;

	UPROPERTY()
	float TurnRate = 0.f;

	UPROPERTY()
	bool bPlayerPullingCar = false;

	UPROPERTY()
	bool bCurrentlyLaunching = false;

	UPROPERTY()
	float LaunchVelocity = 0.f;

	bool bPlayerDrivingCar = false;	
}