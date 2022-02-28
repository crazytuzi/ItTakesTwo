import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspBomb;

class UWaspBomberTeam : UHazeAITeam
{
    private TSet<AWaspBomb> WaspBombPool;
    
    AWaspBomb GetAvailableBomb()
    {
        for (AWaspBomb Bomb : WaspBombPool)
        {
            if (Bomb.IsAvailable())
                return Bomb;
        }
        if (WaspBombPool.Num() < 20)
        {
            // Spawn a new bomb
            AWaspBomb NewBomb = Cast<AWaspBomb>(SpawnActor(AWaspBomb::StaticClass()));
            WaspBombPool.Add(NewBomb);
			NewBomb.MakeNetworked(this, WaspBombPool.Num());
            return NewBomb;
        }
        return nullptr;
    }
}