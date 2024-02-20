using System.ComponentModel.DataAnnotations;

namespace _3tier_webapp.Data
{
    public class VoteOption
    {
        [Key]
        public string OptionText { get; set; }
        public int VoteCount { get; set; }
    }
}