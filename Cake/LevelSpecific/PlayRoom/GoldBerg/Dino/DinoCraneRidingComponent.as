import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCrane;

class UDinoCraneRidingComponent : UActorComponent
{
	ADinoCrane DinoCrane;
	FVector SteeringInput;
	FVector2D RawInput;
	FRotator ControlRotation;
	float VerticalInput;
	bool bIsBiting = false;
};

void InitDinoCraneRiding(AHazePlayerCharacter Player, ADinoCrane DinoCrane)
{
	auto Comp = UDinoCraneRidingComponent::GetOrCreate(Player);
	Comp.DinoCrane = DinoCrane;
}

void RemoveDinoCraneRiding(AHazePlayerCharacter Player, ADinoCrane DinoCrane)
{
	auto Comp = UDinoCraneRidingComponent::GetOrCreate(Player);
	Comp.DinoCrane = nullptr;
}

UDinoCraneRidingComponent GetDinoRidingComponent(ADinoCrane DinoCrane)
{
	if (DinoCrane.RidingPlayer == nullptr)
		return nullptr;
	return UDinoCraneRidingComponent::GetOrCreate(DinoCrane.RidingPlayer);
}

void DisableDinoCraneEatOtherPlayer(UObject Instigator)
{
	for(auto Player : Game::GetPlayers())
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(Player);
		if (RidingComp == nullptr)
			continue;
		if (RidingComp.DinoCrane != nullptr)
			RidingComp.DinoCrane.DisableEatOtherPlayerInstigators.AddUnique(Instigator);
	}
}

void EnableDinoCraneEatOtherPlayer(UObject Instigator)
{
	for(auto Player : Game::GetPlayers())
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(Player);
		if (RidingComp == nullptr)
			continue;
		if (RidingComp.DinoCrane != nullptr)
			RidingComp.DinoCrane.DisableEatOtherPlayerInstigators.Remove(Instigator);
	}
}