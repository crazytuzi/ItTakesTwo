import Cake.LevelSpecific.Music.KeyBird.Capabilities.KeyBirdAction;

import void KillKeyBird_NoEffect(AHazeActor) from "Cake.LevelSpecific.Music.KeyBird.KeyBird";

class UKeyBirdActionDie : UKeyBirdAction
{
	void Execute() override
	{
		KillKeyBird_NoEffect(Owner);
	}
}
